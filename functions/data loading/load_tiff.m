function data = load_tiff(filename)
%{
load_tiff.m

CU Boulder METALS Project
Comments Updated: 29 October 2024
Samuel Hatton

Inputs:
    filename    String with the file path of the target tiff image
Outputs:
    data        

%}
    t = Tiff(filename);
    data = read(t);
end