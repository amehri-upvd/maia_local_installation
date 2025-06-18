#!/bin/bash
set -euo pipefail

# ============================================================================
# MAIA INSTALLATION PREREQUISITES
# ============================================================================
#
# System Dependencies:
# -------------------
# 1. git - Version control system for cloning the Maia repository
# 2. cmake - Cross-platform build system generator
# 3. make - Build automation tool
# 4. python3 - Python programming language (version 3.9+ recommended, 3.10/3.11 preferred)
# 5. pip - Python package installer
#
# System Libraries:
# ----------------
# 1. zlib1g-dev - Compression library development files
#    - Required for CGNS file compression support
# 2. libbz2-dev - High-quality block-sorting file compressor library
#    - Required for additional compression algorithms
# 3. build-essential - C/C++ development tools
#    - Required for compiling C++ components
# 4. software-properties-common - Manage software repositories
#    - Required for adding PPAs (e.g., deadsnakes for Python)
# 5. python3-dev - Python header files
#    - Required for building Python C extensions
# 6. python3-venv - Python virtual environment support (optional)
#    - Required if using venv for virtual environment creation
#    - Alternative: virtualenv can be used instead
# 7. libparmetis-dev - Parallel graph partitioning library
#    - Required for efficient domain decomposition in parallel simulations
#    - Enables balanced distribution of computational load across processors
# 7. libptscotch-dev - Parallel graph partitioning and sparse matrix ordering library
#    - Alternative to ParMETIS for mesh partitioning
#    - Provides advanced algorithms for optimizing parallel computations
# 8. libopenmpi-dev - Open MPI development files
#    - Required for parallel computing capabilities in C++ applications
#    - Provides implementation of the Message Passing Interface (MPI) standard
#    - Enables efficient communication between processes in distributed computing
#
# Python Packages:
# ---------------
# 1. numpy - Scientific computing package
#    - Core dependency for numerical operations and data handling
# 2. setuptools - Package development process library
#    - Required for building and installing dependencies
# 3. wheel - Built-package format for Python
#    - Improves package installation speed and reliability
# 4. pytest - Testing framework
#    - Used for Maia's test suite
# 5. pytest-html - Plugin for pytest that generates HTML reports
#    - Enhances test result visualization
# 6. mpi4py (version 3.1.5) - Python bindings for MPI
#    - Required for parallel computing capabilities
# 7. cython (version 0.29.36) - C extensions for Python
#    - Used for performance-critical parts of Maia
# 8. h5py - Python interface for HDF5 binary data format
#    - Essential for CGNS data storage operations
#    - Requires parallel HDF5 support (libhdf5-openmpi-dev) for parallel I/O
#    - Must be built with --no-binary=h5py and HDF5_MPI="ON" for parallel support
# 9. PyYAML - YAML parser and emitter
#    - Used for configuration and test data
# 10. jupyter - Interactive notebook environment
#    - Provides web-based interface for code execution and visualization
#    - Enables interactive data exploration and analysis
# 11. ipyparallel - Interactive parallel computing
#    - Enables parallel execution in Jupyter notebooks
#    - Provides tools for distributing computation across multiple cores/nodes
# 12. matplotlib - Plotting library
#    - Used for creating visualizations and plots in notebooks
#    - Essential for data visualization and analysis
#
# Installation Command for System Dependencies (Ubuntu/Debian):
# ----------------------------------------------------------
# sudo apt-get install git cmake make python3 pip zlib1g-dev libbz2-dev build-essential software-properties-common python3-dev python3-venv libparmetis-dev libptscotch-dev libopenmpi-dev libhdf5-dev libhdf5-openmpi-dev hdf5-tools python3-notebook
#
# ============================================================================

# Colors for log messages
GREEN='\e[1;32m'
RED='\e[1;31m'
NC='\e[0m' # No Color

log_info() {
  echo -e "${GREEN}$1${NC}"
}

log_error() {
  echo -e "${RED}$1${NC}" >&2
}

# Trap errors and display the line number
trap 'log_error "Error on line ${LINENO}. Exiting."; cleanup' ERR
trap 'log_error "Script interrupted."; cleanup' INT TERM


# Function to check for required commands and system dependencies
check_dependencies() {
  local missing_deps=false
  
  # Check for required commands
  log_info "Checking for required commands..."
  for cmd in git cmake make python3 pip; do
    if ! command -v "$cmd" &> /dev/null; then
      log_error "Required command '$cmd' not found. Please install it."
      missing_deps=true
    fi
  done
  
  # Check for required system packages
  log_info "Checking for required system libraries..."
  local required_packages=("zlib1g-dev" "libbz2-dev" "build-essential" "software-properties-common" "python3-dev" "libopenmpi-dev" "libptscotch-dev" "libparmetis-dev" "hdf5-tools" "libhdf5-dev" "libhdf5-openmpi-dev")
  local missing_packages=()
  
  for pkg in "${required_packages[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
      missing_packages+=("$pkg")
    fi
  done
  
  if [ ${#missing_packages[@]} -gt 0 ]; then
    log_error "The following required packages are missing:"
    for pkg in "${missing_packages[@]}"; do
      log_error "  - $pkg"
    done
    log_error "Please install them with: sudo apt-get install ${missing_packages[*]}"
    missing_deps=true
  fi
  
  if [ "$missing_deps" = true ]; then
    log_error "Missing dependencies. Please install them and try again."
    exit 1
  else
    log_info "All required dependencies are installed."
  fi
}

# Function to check and install Python 3.8 if needed
# check_install_python38() {
#   log_info "Checking for Python 3.8 availability..."
  
#   # Check if Python 3.8 is already installed
#   if command -v python3.8 &> /dev/null; then
#     log_info "Python 3.8 is already installed."
#     return 0
#   fi
  
#   # Check if we're on a Debian/Ubuntu system
#   if command -v apt-get &> /dev/null; then
#     log_info "Python 3.8 not found. Attempting to install Python 3.8..."
    
#     # Check if deadsnakes PPA is available
#     if ! grep -q "^deb.*deadsnakes" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
#       log_info "Adding deadsnakes PPA for Python 3.8 installation..."
#       if command -v add-apt-repository &> /dev/null; then
#         log_info "Attempting to add deadsnakes PPA..."
#         if ! sudo add-apt-repository -y ppa:deadsnakes/ppa; then
#           log_error "Failed to add deadsnakes PPA. You may need to install Python 3.8 manually."
#           log_info "Continuing with available Python version..."
#           return 1
#         fi
#       else
#         log_error "add-apt-repository command not found. You may need to install Python 3.8 manually."
#         log_info "Continuing with available Python version..."
#         return 1
#       fi
#     fi
    
#     log_info "Updating package lists..."
#     if ! sudo apt-get update; then
#       log_error "Failed to update package lists. Continuing with available Python version..."
#       return 1
#     fi
    
#     log_info "Installing Python 3.8..."
#     if ! sudo apt-get install -y python3.8 python3.8-venv python3.8-dev; then
#       log_error "Failed to install Python 3.8. Continuing with available Python version..."
#       return 1
#     fi
    
#     log_info "Python 3.8 installed successfully."
#     return 0
#   else
#     log_info "Non-Debian/Ubuntu system detected. Please install Python 3.8 manually if needed."
#     log_info "Continuing with available Python version..."
#     return 1
#   fi
# }

# Function to check and install Python 3.9 if needed
check_install_python39() {
  log_info "Checking for Python 3.9 availability..."
  
  # Check if Python 3.9 is already installed
  if command -v python3.9 &> /dev/null; then
    log_info "Python 3.9 is already installed."
    return 0
  fi
  
  # Check if we're on a Debian/Ubuntu system
#   if command -v apt-get &> /dev/null; then
#     log_info "Python 3.9 not found. Attempting to install Python 3.9..."
    
#     # Check if deadsnakes PPA is available
#     if ! grep -q "^deb.*deadsnakes" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
#       log_info "Adding deadsnakes PPA for Python 3.9 installation..."
#       if command -v add-apt-repository &> /dev/null; then
#         log_info "Attempting to add deadsnakes PPA..."
#         if ! sudo add-apt-repository -y ppa:deadsnakes/ppa; then
#           log_error "Failed to add deadsnakes PPA. You may need to install Python 3.9 manually."
#           log_info "Continuing with available Python version..."
#           return 1
#         fi
#       else
#         log_error "add-apt-repository command not found. You may need to install Python 3.9 manually."
#         log_info "Continuing with available Python version..."
#         return 1
#       fi
#     fi
    
#     log_info "Updating package lists..."
#     if ! sudo apt-get update; then
#       log_error "Failed to update package lists. Continuing with available Python version..."
#       return 1
#     fi
    
#     log_info "Installing Python 3.9..."
#     if ! sudo apt-get install -y python3.9 python3.9-venv python3.9-dev; then
#       log_error "Failed to install Python 3.9. Continuing with available Python version..."
#       return 1
#     fi
    
#     log_info "Python 3.9 installed successfully."
#     return 0
#   else
#     log_info "Non-Debian/Ubuntu system detected. Please install Python 3.9 manually if needed."
#     log_info "Continuing with available Python version..."
#     return 1
#   fi
 }

# Function to create and activate virtual environment
setup_virtual_env() {
  log_info "Setting up Python virtual environment..."
  
  # Try to find Python 3.10 or 3.11 first (more compatible with Maia)
  # Python 3.9 is also fully supported and will be installed if not available
  local python_cmd=""
  
  # Check for Python 3.10 or 3.11 first (preferred versions)
  for py_version in python3.8 python3.9 python3.10 python3.11; do
    if command -v $py_version &> /dev/null; then
      python_cmd=$py_version
      log_info "Using $python_cmd for virtual environment"
      break
    fi
  done
  
  # If Python 3.9 or higher is not found, try to install Python 3.9
  if [ -z "$python_cmd" ] || [[ "$python_cmd" == "python3.8" ]]; then
    log_info "No Python 3.9 or higher detected. Attempting to install Python 3.9..."
    if check_install_python39; then
      # Check if Python 3.9 is now available after installation
      if command -v python3.9 &> /dev/null; then
        python_cmd="python3.9"
        log_info "Using newly installed Python 3.9 for virtual environment"
      fi
    fi
  fi
  
  # If specific versions not found, fall back to python3
  if [ -z "$python_cmd" ]; then
    if command -v python3 &> /dev/null; then
      python_cmd="python3"
      # Check Python version
      py_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
      log_info "Using python3 (version $py_version) for virtual environment"
      
      # Warn if Python 3.12+ is detected
      if [[ "$py_version" == 3.12* ]] || [[ "$py_version" > 3.12 ]]; then
        log_info "Warning: Python $py_version detected. Maia may not be compatible with Python 3.12+."
        log_info "Consider installing Python 3.10 or 3.11 for better compatibility."
      fi
    else
      log_error "Python3 is required but not found."
      return 1
    fi
  fi
  
  # Create virtual environment with the selected Python version
  $python_cmd -m venv maia-venv || {
    log_info "Failed to create venv with $python_cmd -m venv, trying virtualenv..."
    if command -v virtualenv &> /dev/null; then
      virtualenv --python=$python_cmd maia-venv || {
        log_error "Failed to create virtual environment with virtualenv."
        return 1
      }
    else
      log_error "Neither python venv nor virtualenv is available. Please install one of them."
      return 1
    fi
  }
  
  # Activate the virtual environment
  source maia-venv/bin/activate || {
    log_error "Failed to activate virtual environment."
    return 1
  }
  
  # Upgrade pip to latest version
  pip install --upgrade pip || {
    log_error "Failed to upgrade pip."
    return 1
  }
  
  # Install required Python packages
  #
  # Module List and Purpose:
  # ----------------------
  # 1. numpy - Scientific computing package providing support for arrays, matrices, and mathematical functions
  #    - Core dependency for Maia's numerical operations and data handling
  #    - Used by Maia for efficient array operations and numerical algorithms
  #
  # 2. setuptools - Package development process library that facilitates packaging Python projects
  #    - Required for building and installing Maia and its dependencies
  #    - Handles dependency resolution and package metadata
  #
  # 3. wheel - Built-package format for Python that provides faster installation
  #    - Improves package installation speed and reliability
  #    - Used for binary distribution format
  #
  # 4. pytest - Testing framework that makes it easy to write small tests
  #    - Used for Maia's test suite to ensure code quality and functionality
  #    - Supports both simple unit tests and complex functional tests
  #
  # 5. pytest-html - Plugin for pytest that generates HTML reports for test results
  #    - Generates visual test reports for better analysis of test results
  #    - Enhances test result visualization and reporting
  #
  # 6. mpi4py (version 3.0.3) - Python bindings for the Message Passing Interface (MPI) standard
  #    - Required for parallel computing capabilities in Maia
  #    - Version 3.0.3 specifically chosen for compatibility with system MPI implementations
  #    - Later versions may have compatibility issues with certain MPI implementations
  #
  # 7. cython (version 0.29.36) - Language that makes writing C extensions for Python as easy as Python
  #    - Used for performance-critical parts of Maia to achieve C-like speed
  #    - Version 0.29.36 is the last version before 3.0 which introduced breaking changes
  #    - Maia's C++ bindings rely on this specific version for compatibility
  #
  # 8. h5py - Python interface for the HDF5 binary data format
  #    - Essential for reading and writing HDF5 files which are used for CGNS data storage
  #    - Maia uses this for efficient I/O operations with large scientific datasets
  #
  # 9. PyYAML - YAML parser and emitter for Python
  #    - Used for configuration file parsing and data serialization
  #    - Required specifically for Maia's pytree tests that use YAML for test data
  #
  # 10. sphinx - Documentation generator
  #    - Required for building Maia's documentation
  #    - Used with extensions for API documentation and more
  #
  # 11. sphinx-rtd-theme - Read the Docs theme for Sphinx
  #    - Provides a clean, professional documentation theme
  #    - Required for Maia's documentation styling
  #
  # 12. sphinx-tabs - Tabbed content for Sphinx
  #    - Enables tabbed content in documentation
  #    - Used for showing multiple code examples or configurations
  #
  # Version constraints are applied to ensure compatibility with Maia's codebase:
  # - mpi4py==3.0.3: Pinned for compatibility with system MPI implementations
  # - cython==0.29.36: Last version before 3.0 which introduced breaking changes
  #
#   pip install numpy setuptools wheel pytest pytest-html "mpi4py<3.1.0" "cython<3.0.0" || {
  pip install "numpy==1.26.0" setuptools wheel pytest pytest-html "mpi4py==3.1.5" "cython==0.29.36" PyYAML pybind11 sphinx sphinx-rtd-theme sphinx-tabs jupyter ipyparallel matplotlib || {
    log_error "Failed to install required Python packages in virtual environment."
    return 1
  }
  
  # Configure and install h5py with parallel HDF5 support
  log_info "Installing h5py with parallel HDF5 support..."
  
  # Set environment variables for parallel HDF5 build
  export CC=mpicc
  export HDF5_MPI="ON"
  
  # Check if h5cc is available to verify HDF5 configuration
  if command -v h5cc &> /dev/null; then
    log_info "HDF5 configuration:"
    h5cc -showconfig || log_info "Could not show HDF5 configuration, but continuing..."
    # Check if HDF5 was built with parallel support
    if h5cc -showconfig | grep -q "Parallel HDF5: yes"; then
      log_info "HDF5 was built with parallel support."
    else
      log_error "WARNING: HDF5 was NOT built with parallel support!"
      log_error "This will cause failures in parallel I/O operations."
      log_error "Please ensure your HDF5 installation was built with --enable-shared --enable-parallel"
    fi
  else
    log_info "h5cc not found. Cannot verify HDF5 configuration, but continuing..."
    log_info "Checking for libhdf5-openmpi-dev package..."
    if ! dpkg-query -W -f='${Status}' "libhdf5-openmpi-dev" 2>/dev/null | grep -q "install ok installed"; then
      log_error "WARNING: libhdf5-openmpi-dev package is not installed!"
      log_error "This package is required for parallel HDF5 support."
      log_error "Please install it with: sudo apt-get install libhdf5-openmpi-dev"
    fi
  fi
  
  # Install h5py with parallel support
  log_info "Running: pip install --no-binary=h5py h5py"
  pip install --no-binary=h5py h5py || {
    log_error "Failed to install h5py with parallel support. Falling back to standard installation."
    # Fallback to standard h5py installation if parallel build fails
    pip install h5py || {
      log_error "Failed to install h5py. This may affect Maia's functionality."
      return 1
    }
  }
  
  # Verify h5py parallel support
  log_info "Verifying h5py parallel support..."
  if $python_cmd -c "import h5py; print('Parallel HDF5 support:', h5py.get_config().mpi)" 2>/dev/null | grep -q "True"; then
    log_info "h5py was built with parallel HDF5 support."
  else
    log_error "WARNING: h5py was NOT built with parallel HDF5 support!"
    log_error "This will cause failures in parallel I/O operations."
    log_error "Please ensure your HDF5 installation was built with --enable-shared --enable-parallel"
    log_error "You may need to install libhdf5-openmpi-dev or equivalent package for your system."
  fi
  
  log_info "Virtual environment setup completed successfully."
  return 0
}

# Function to clean up if installation fails
cleanup() {
  log_info "Cleaning up..."
  if [ -d "Maia/build" ]; then
    log_info "Removing build directory..."
    rm -rf "Maia/build"
  fi
  if [ -d "Maia/Dist" ]; then
    log_info "Removing Dist directory..."
    rm -rf "Maia/Dist"
  fi
  log_info "Cleanup completed."
}

# Main installation function
main() {
  log_info "Starting Maia installation process..."
  
  # Check for required dependencies
  check_dependencies
  
  # Check for Python 3.9 availability
  check_install_python39 || log_info "Proceeding with available Python versions..."
  
  # Clone the repository if it does not already exist
  if [ ! -d "Maia" ]; then
    log_info "Cloning the Maia repository..."
    git clone https://github.com/onera/Maia.git || {
      log_error "Failed to clone the Maia repository!"
      exit 1
    }
  fi
  
  cd Maia || {
    log_error "Failed to enter Maia directory."
    exit 1
  }
  log_info "Entered 'Maia' directory."
  
  log_info "Updating submodules recursively..."
  git submodule update --init || {
    log_info "Warning: Some submodules failed to update. Continuing with basic installation."
  }
  
  # Update submodule 'paradigmA' within external/paradigm if it exists
  if [ -d "external/paradigm" ]; then
    log_info "Attempting to update confidential 'paradigma' submodule..."
    if (cd external/paradigm && git submodule update --init); then
      log_info "Successfully updated confidential submodule"
    else
      log_info "Skipping confidential submodule update - requires ONERA credentials"
    fi
  else
    log_info "Skipping optional confidential submodule (directory not present)"
  fi
  
  mkdir -p Dist || {
    log_error "Failed to create 'Dist' directory."
    exit 1
  }
  log_info "'Dist' directory created."
  
  mkdir -p build || {
    log_error "Failed to create 'build' directory."
    exit 1
  }
  cd build || {
    log_error "Failed to enter 'build' directory."
    exit 1
  }
  log_info "Entered 'build' directory."
  
  # Allow BUILD_TYPE override via environment variable; default to Debug
  BUILD_TYPE=${BUILD_TYPE:-Debug}
  
  # Setup virtual environment
  setup_virtual_env || {
    log_error "Failed to setup virtual environment. Exiting."
    exit 1
  }
  
  # Get Python and NumPy information
  PYTHON_EXECUTABLE="$(pwd)/maia-venv/bin/python"
  PYTHON_VERSION=$(${PYTHON_EXECUTABLE} -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
  PYTHON_INCLUDE_DIR=$(${PYTHON_EXECUTABLE} -c "import sysconfig; print(sysconfig.get_path('include'))")
  NUMPY_INCLUDE_DIR=$(${PYTHON_EXECUTABLE} -c "import numpy; print(numpy.get_include())")
  
  log_info "Python executable: ${PYTHON_EXECUTABLE}"
  log_info "Python version: ${PYTHON_VERSION}"
  log_info "Python include directory: ${PYTHON_INCLUDE_DIR}"
  log_info "NumPy include directory: ${NUMPY_INCLUDE_DIR}"
  
  if [ -z "${NUMPY_INCLUDE_DIR}" ]; then
    log_error "Failed to locate NumPy include directory."
    exit 1
  fi
  
  log_info "Running CMake configuration..."
  cmake ../ \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/../Dist" \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_EXE_LINKER_FLAGS='-lz -lbz2' \
    -DCMAKE_SHARED_LINKER_FLAGS='-lz -lbz2' \
    -DPDM_ENABLE_EXTENSION_PDMA=ON \
    -DPDM_ENABLE_LONG_G_NUM=OFF \
    -DPDM_ENABLE_EXTENSION=ON \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
    -DPYTHON_EXECUTABLE="${PYTHON_EXECUTABLE}" \
    -DPython_ROOT_DIR="$(pwd)/maia-venv" \
    -DPython_EXECUTABLE="${PYTHON_EXECUTABLE}" \
    -DPython_INCLUDE_DIRS="${PYTHON_INCLUDE_DIR}" \
    -DPython_NumPy_INCLUDE_DIRS="${NUMPY_INCLUDE_DIR}" \
    -DPython3_EXECUTABLE="${PYTHON_EXECUTABLE}" \
    -DPython3_INCLUDE_DIRS="${PYTHON_INCLUDE_DIR}" \
    -DPython3_NumPy_INCLUDE_DIRS="${NUMPY_INCLUDE_DIR}" \
    -DPython_NumPy=ON || {
      log_error "CMake configuration failed. Please check the error messages above."
      exit 1
    }
  
  log_info "CMake configuration successful. Starting build..."
  
  # Try to build with automatic parallelism first
  log_info "Starting build with 'make -j' (automatic parallelism)..."

  make -j
  source source.sh
  make maia_sphinx
  cd ../doc
  sphinx-build -M html ~/dev-Maia/maia/doc  outputdir
  
#   if ! make -j; then
#     log_info "Build with automatic parallelism failed. Trying with reduced parallelism..."
    
#     # Get number of cores for fallback options
#     local num_cores=$(nproc)
#     # Retry with half the cores
#     local reduced_cores=$((num_cores / 2))
#     if [ $reduced_cores -lt 1 ]; then
#       reduced_cores=1
#     fi
    
#     log_info "Retrying build with ${reduced_cores} parallel jobs..."
#     if ! make -j${reduced_cores}; then
#       log_info "Build with reduced parallelism failed. Trying with single job..."
      
#       # Last attempt with a single job
#       if ! make -j1; then
#         log_error "Build failed after multiple attempts."
#         cleanup
#         exit 1
#       fi
#     fi
#   fi
  
#   log_info "Build successful. Installing..."
#   make install || {
#     log_error "Installation failed."
#     cleanup
#     exit 1
#   }
  
  log_info "MAIA SETUP COMPLETED SUCCESSFULLY."
  log_info "To use Maia, activate the virtual environment with: source $(pwd)/maia-venv/bin/activate"
 }

# Run the main function
main
