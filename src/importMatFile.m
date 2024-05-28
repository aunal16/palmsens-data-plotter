function dataTable = importMatFile(matFile)
%IMPORTFILE(matFile)
%  Imports data from the specified file
%  matFile:  file to read

% Import the file
dataStruct = load('-mat', matFile);

dataTable = struct2table(dataStruct);
end