# METALS-CU
 Repository for all code developed in support of the METALS MAPS project. AMReC, López Jiménez Lab

### DARPA Program Page
[METALS: Multiobjective Engineering and Testing of Alloy Structures](https://www.darpa.mil/research/programs/multiobjective-engineering-and-testing-of-alloy-structures)

### Repository Contributers
- [Samuel Hatton](https://github.com/samuelhattonCU), BAM Research Assistant

### Acknowledgements
All of this work is lead by [David Marshall](https://www.colorado.edu/aerospace/david-marshall) and [Francisco López Jiménez](https://www.colorado.edu/aerospace/francisco-lopez-jimenez). Thanks to [Ankita Gupta](https://www.linkedin.com/in/ankita-gupta-362a713a) for her work on the project; and to our colaborators at Teledyne, [Sergio Lucato](https://www.linkedin.com/in/lucato) for his leadership and [Akshat Agha](https://www.linkedin.com/in/akshatagha) for his patience and support. Thanks to [Spencer Dansereau](https://www.linkedin.com/in/spencer-dansereau) for helping a ton with trouble shooting nearly all of our test procedures and analysis code.

## Dependencies
- MATLAB R2023b or later
- Image Processing Toolbox
- Signal Processing Toolbox
- Curve Fitting Toolbox

## Usage
1. Clone repository
2. Add function directories to MATLAB path
3. Run analysis scripts from scripts/ directory

## Main Components
- Data Loading: Tools for importing Instron, VIC-3D, and FLIR data
- Analysis: Functions for mechanical property calculation
- Visualization: Plotting tools for force-displacement curves
- Thermal Analysis: FLIR data processing utilities

## Documentation
All functions include detailed headers with:
- Input/Output specifications
- Methodology description
- Dependencies list

## Directory Structure
```
METALS-CU/
├── Functions/
│   ├── Analysis and Plotting/    # Functions for data processing and visualization
│   └── Data Loading/             # Functions for importing VIC-3D, Instron, and FLIR data
│
├── Scripts/                      # Standalone analysis scripts
│
└── Local/                        # Local configuration files (not in repo)
                                  # Note: Largely deprecated as of Jan. 2025
```
