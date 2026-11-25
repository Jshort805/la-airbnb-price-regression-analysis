#Install the packages for this project
#Run once per environment (the devcontainer does it automatically).

pkgs<- c("languageserver") # languageserver = VS Code R support
missing_pkgs<- setdiff(pkgs, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs)
}