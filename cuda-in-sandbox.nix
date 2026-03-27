{
  runCommand,
  cudaPackages,
  lib,
}:

runCommand "saxdemo"
  {
    requiredSystemFeatures = [ "cuda" ];
  }
  ''
    ${lib.getExe cudaPackages.saxpy} &> $out
  ''
