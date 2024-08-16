function data = vicExtensometer_csv_parser(filename,NumHeaderLines,VariableNamesLine)
%{
    Samuel Hatton for METALS project
    5/30/24
    
    Takes in a filename string, loads the csv into a table w/ variable
    names and units, outputs table
    
    Inputs:
        filename            string containing file name
        NumHeaderLines      (OPTIONAL) integer, 3 by default
        VariableNamesLine   (OPTIONAL) integer, 2 by default
    
    Outputs:
        data                table data type containing the data from the
                            csv, variable names
    
    Dependencies:

%}

    % optional input handling
    if ~exist('NumHeaderLines','var')
        NumHeaderLines = 2;
    end
    if ~exist('VariableNamesLine','var')
        VariableNamesLine = 2;
    end


    % suppress table wanrings:
    warning('off','all')
    
    % extract data to a table
    data = readtable(filename,"NumHeaderLines",NumHeaderLines,"VariableNamesLine",VariableNamesLine);
    data = addprop(data,{'FileName'},{'table'});
    data.Properties.CustomProperties.FileName = filename;

    % turn back on warnings
    warning('on','all')

    % % Store some file metadata in the table
    % idx = strfind(filename,'_');
    % if ~isempty(idx)
    %     if (length(idx) >= 2) && (length(filename) >= idx(2) + 8) 
    %         dateString = filename(idx(2)+1:idx(2)+8);
    %         testdate = datetime(dateString,'InputFormat','uuuuMMdd');
    %         data.Properties.CustomProperties.TestDate = testdate;
    %     else
    %         data.Properties.CustomProperties.TestDate = datetime("today");
    %     end
    % end
    % 
    % % remove extreneous first column:
    % c1 = data(:,1);
    % c1Name = c1.Properties.VariableNames;
    % if ~strcmp(c1Name,'Time')
    %     data(:,1) = [];
    % end
end