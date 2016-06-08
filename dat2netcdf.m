function dat2netcdf(dirName,var2Read)
   if nargin < 1
        error('dataProcessingIR4: dirName is a required input')
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
        save_path = java.lang.String(dirName(2));
        if(length(dirName)>2)
            logPath = java.lang.String(dirName(3));
        else
            logPath = java.lang.String(dirName(2));
        end
	else
		save_path = java.lang.String(dirName(1));
		logPath = java.lang.String(dirName(1));
    end
    if(save_path.charAt(save_path.length-1) ~= '/')
        save_path = save_path.concat('/');
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
                writeFile(fileT,var2Read,yearC,savePath,logPath);
            end
            
        else
            if isequal(dirData(f).isdir,1)
                newPath = char(path.concat(dirData(f).name));
                if length(dirName) > 2
                    dat2nefcdf({newPath,char(save_path.concat(dirData(f).name)),char(logPath)});
                else
                    dat2nefcdf({newPath,char(save_path.concat(dirData(f).name))});
                end
            end
        end
    end
end

function writeFile(fileT,var2Read,yearC,savePath,logPath)
    % New file configuration
    if ~exist(char(savePath),'dir')
        mkdir(char(savePath));
    end

    try
        latDataSet = [-89.8750:0.25:90];
        lonDataSet = [0.1250:0.25:360];
        tmp = fileT.split('/');
        tmp = char(tmp(end).split('.dat'));
        newName = strcat(tmp,'.nc');
        newFile = char(savePath.concat(newName));
        GLOBALNC = netcdf.getConstant('NC_GLOBAL');

        % Creating new nc file
        if exist(newFile,'file')
            delete(newFile);
        end
        ncid = netcdf.create(newFile,'NETCDF4');

        % Adding file dimensions
        latdimID = netcdf.defDim(ncid,'lat',length(latDataSet));
        londimID = netcdf.defDim(ncid,'lon',length(lonDataSet));
        timedimID = netcdf.defDim(ncid,'time',netcdf.getConstant('NC_UNLIMITED'));

        % Global params
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment_id',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment_rip',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'institution',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'realm',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'modeling_realm',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'version',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'downscalingModel',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'experiment_id',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
%         netcdf.copyAtt(ncoid,GLOBALNC,'parent_experiment',ncid,GLOBALNC);
        netcdf.putAtt(ncid,GLOBALNC,'frequency','monthly');
        netcdf.putAtt(ncid,GLOBALNC,'year',num2str(yearC));
        netcdf.putAtt(ncid,GLOBALNC,'data_analysis_institution','CIGEFI - Universidad de Costa Rica');
        netcdf.putAtt(ncid,GLOBALNC,'data_analysis_institution',char(datetime('today')));
        netcdf.putAtt(ncid,GLOBALNC,'data_analysis_contact','Roberto Villegas D: roberto.villegas@ucr.ac.cr');

        % Adding file variables
        varID = netcdf.defVar(ncid,var2Read,'float',[timedimID,latdimID,londimID]);
        [~] = netcdf.defVar(ncid,'time','float',timedimID);
        latvarID = netcdf.defVar(ncid,'lat','float',latdimID);
        lonvarID = netcdf.defVar(ncid,'lon','float',londimID);

        netcdf.endDef(ncid);
        % Writing the data into file
        netcdf.putVar(ncid,latvarID,latDataSet);
        netcdf.putVar(ncid,lonvarID,lonDataSet);
        netcdf.close(ncoid);
    catch exception
        disp(exception.message);
        netcdf.close(ncid);
        netcdf.close(ncoid);
        if exist(newFile,'file')
            delete(newFile);
        end
        fid = fopen(strcat(char(logPath),'log.txt'), 'at');
        fprintf(fid, '[ERROR][%s] %s\n %s\n\n',char(datetime('now')),char(fileT),char(exception.message));
        fclose(fid);
        return;
    end
end