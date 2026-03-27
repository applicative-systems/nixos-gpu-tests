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
    ${lib.getExe cudaPackages.saxpy} 2>&1 | tee "$out"
  ''
