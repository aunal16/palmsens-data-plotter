function data = importMatFile(matFile)
%IMPORTFILE(matFile)
%  Imports data from the specified file
%  matFile:  file to read

% Import the file
data = load('-mat', matFile);

end