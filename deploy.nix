{
  git,
  rsync,
  writeShellApplication
}:
writeShellApplication {
  name = "deploy";
  runtimeInputs = [
    git
    rsync
  ];
  text = builtins.readFile ./deploy.sh;
}
