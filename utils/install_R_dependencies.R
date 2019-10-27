# Define packages to install
#std_packages <- c("data.table", "plyr", "dplyr", "reshape", "library", "gap", "sfsmisc")
std_packages <- c("data.table", "plyr", "dplyr", "reshape", "gap", "sfsmisc")
bioc_packages <- c("IRanges")

# Define R library path
rLibPath <- paste0(path.expand("~"), "/R/")
print(paste0("Installing libraries at ", rLibPath))
.libPaths(rLibPath)

# Update current packages
print("Updating packages...")
update.packages(lib=rLibPath)

# Install BiocManager
print("Installing BiocManager...")
update.packages(ask=FALSE, lib=rLibPath)
install.packages("BiocManager", dependencies=TRUE, lib=rLibPath)

# Install STD packages
print("Installing Standard R Packages...")
for(pack in std_packages) {
  print(paste0("Installing ", pack))
  install.packages(pack, dependencies=TRUE, lib=rLibPath)
  if ( ! library(pack, character.only=TRUE, logical.return=TRUE) ) {
    quit(status=1, save="no")
  }
}

# Install BiocManager packages
print("Installing BiocManager Packages...")
for (pack in bioc_packages) {
  print(paste0("Installing ",pack))
  BiocManager::install(pack, lib=rLibPath)
  if ( ! library(pack, character.only=TRUE, logical.return=TRUE) ) {
    quit(status=1, save="no")
  }
}

# Done
print("ALL DONE")
