function dat2netcdf(dirName,var2Read)
   if nargin < 1
        error('dat2netcdf: dirName is a required input')
    else
        dirName = strrep(dirName,'\','/'); % Clean dirName var
    end
    switch nargin
        case 1 % Validates if the var2Read param is received
            temp = java.lang.String(dirName(1)).split('/');
            temp = temp(end).split('_');
            var2Read = char(temp(1)); % Default value is taken from the path
    end
    dirData = dir(char(dirName(1)));  % Get the data for the current directory
    path = java.lang.String(dirName(1));
    if(path.charAt(path.length-1) ~= '/')
        path = path.concat('/');
    end
    if(length(dirName)>1)
        savePath = java.lang.String(dirName(2));
        if(length(dirName)>2)
            logPath = java.lang.String(dirName(3));
        else
            logPath = java.lang.String(dirName(2));
        end
	else
		savePath = java.lang.String(dirName(1));
		logPath = java.lang.String(dirName(1));
    end
    if(savePath.charAt(savePath.length-1) ~= '/')
        savePath = savePath.concat('/');
    end
    if(logPath.charAt(logPath.length-1) ~= '/')
        logPath = logPath.concat('/');
    end
    
    try
		experimentParent = path.substring(0,path.lastIndexOf(strcat('/',var2Read)));
		experimentName = experimentParent.substring(experimentParent.lastIndexOf('/')+1);
    catch
        experimentName = '[CIGEFI]'; % Dafault value
    end
    processing = 0;
    for f = 3:length(dirData)
        fileT = path.concat(dirData(f).name);
        ext = fileT.substring(fileT.lastIndexOf('.')+1);
        if(ext.equalsIgnoreCase('dat'))
            if ~strcmp(experimentName,'[CIGEFI]')
                if(~processing)
                    fprintf('Processing: %s\n',char(experimentName));
                    processing = 1;
                    if ~exist(char(logPath),'dir')
                        mkdir(char(logPath));
                    end
                    if(exist(strcat(char(logPath),'log.txt'),'file'))
                        delete(strcat(char(logPath),'log.txt'));
                    end
                end
                writeFile(fileT,var2Read,savePath,logPath);
            end
            
        else
            if isequal(dirData(f).isdir,1)
                newPath = char(path.concat(dirData(f).name));
                if length(dirName) > 2
                    if nargin > 1
                        dat2netcdf({newPath,char(savePath.concat(dirData(f).name)),char(logPath)},var2Read);
                    else
                        dat2netcdf({newPath,char(savePath.concat(dirData(f).name)),char(logPath)});
                    end
                else
                    if nargin > 1
                        dat2netcdf({newPath,char(savePath.concat(dirData(f).name))},var2Read);
                    else
                        dat2netcdf({newPath,char(savePath.concat(dirData(f).name))});
                    end
                end
            end
        end
    end
end

function writeFile(fileT,var2Read,savePath,logPath)
    % New file configuration
    if ~exist(char(savePath),'dir')
        mkdir(char(savePath));
    end
    ncid = NaN;
    newFile = NaN;
    try
        latDataSet = [-89.8750:0.25:90];
        lonDataSet = [0.1250:0.25:360];
        sdata = dlmread(char(fileT));
        tmp = fileT.split('/');
        tmp = char(tmp(end).split('.dat'));
        newName = strcat(tmp,'.nc');
        newFile = char(savePath.concat(newName));

        % Creating new nc file
        if exist(newFile,'file')
            delete(newFile);
        end
        ncid = netcdf.create(newFile,'NETCDF4');

        % Adding file dimensions
        latdimID = netcdf.defDim(ncid,'lat',length(latDataSet));
        londimID = netcdf.defDim(ncid,'lon',length(lonDataSet));

        % Adding file variables
        varID = netcdf.defVar(ncid,var2Read,'float',[londimID,latdimID]);
        latvarID = netcdf.defVar(ncid,'lat','float',latdimID);
        lonvarID = netcdf.defVar(ncid,'lon','float',londimID);
        netcdf.endDef(ncid);
        
        % Writing the data into file
        netcdf.putVar(ncid,latvarID,latDataSet);
        netcdf.putVar(ncid,lonvarID,lonDataSet);
        netcdf.putVar(ncid,varID,sdata');
        
        % Local params
        netcdf.putAtt(ncid,latvarID,'standard_name','latitude');
        netcdf.putAtt(ncid,latvarID,'long_name','Latitude');
        netcdf.putAtt(ncid,latvarID,'units','degrees_north');
        netcdf.putAtt(ncid,latvarID,'actual_range','-89.875f, 89.875f');
        netcdf.putAtt(ncid,latvarID,'axis','Y');
        netcdf.putAtt(ncid,lonvarID,'standard_name','longitude');
        netcdf.putAtt(ncid,lonvarID,'long_name','Longitude');
        netcdf.putAtt(ncid,lonvarID,'units','degrees_east');
        netcdf.putAtt(ncid,lonvarID,'actual_range','0.125f, 359.875f');
        netcdf.putAtt(ncid,lonvarID,'axis','X');
        netcdf.putAtt(ncid,varID,'standard_name','precipitation');
        netcdf.putAtt(ncid,varID,'long_name','Precipitation');
        if strcmp(var2Read,'pr')
            netcdf.putAtt(ncid,varID,'units','mm/day');
        else
            netcdf.putAtt(ncid,varID,'units','°C/day');
        end
        netcdf.close(ncid);
        fid = fopen(strcat(char(logPath),'log.txt'), 'at');
    	fprintf(fid, '[SAVED][%s] %s\n',char(datetime('now')),char(strcat(tmp,'.dat')));
    	fclose(fid);
    	disp(char(strcat({'Data saved:  '},{' '},char(strcat(tmp,'.dat')))));
    catch exception
        disp(exception.message);
        if ~isnan(ncid)
            netcdf.close(ncid);
        end
        if ~isnan(newFile)
            if exist(newFile,'file')
                delete(newFile);
            end
        end
        fid = fopen(strcat(char(logPath),'log.txt'), 'at');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
        fclose(fid);
        return;
    end
end