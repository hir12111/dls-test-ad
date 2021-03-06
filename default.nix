{ pkgs ? import <nixpkgs> { }, dlspkgs ?
  import (fetchTarball "https://github.com/hir12111/dlspkgs/tarball/master") { }
}:
with pkgs;
let
  entrypoint = writeScript "entrypoint.sh" ''
    #!${runtimeShell}
    export USER=epics_user
    ${dlspkgs.procServ}/bin/procServ -q -n ioc -i ^D^C --allow 7011 /bin/TS-EA-IOC-01.sh
    ${dlspkgs.procServ}/bin/procServ -q -n malcolm -i ^D^C --allow 7012 /bin/TS-ML-MALC-01
    # wait forever
    tail -f /dev/null
  '';
in dockerTools.buildImage {
  name = "dls-test-ad";
  tag = "latest";
  runAsRoot = ''
    #!${runtimeShell}
    export PATH=/bin:/usr/bin:/sbin:/usr/sbin:$PATH
    ${dockerTools.shadowSetup}
    useradd -m epics_user
    mkdir /tmp
    chown epics_user /tmp
    chmod 777 /tmp
    ln -s ${runtimeShell} /bin/sh
  '';
  contents = [
    coreutils
    inetutils
    git
    dlspkgs.dls-epics-base
    dlspkgs.edm
    dlspkgs.TS-EA-IOC-01
    dlspkgs.TS-ML-MALC-01
    dlspkgs.procServ
  ];
  config = {
    EntryPoint = [ entrypoint ];
    User = "epics_user";
    ExposedPorts = {
      "5075/tcp" = { };
      "5076/udp" = { };
      "6064/tcp" = { };
      "6064/udp" = { };
      "6065/tcp" = { };
      "6065/udp" = { };
      "6075/tcp" = { };
      "7001/tcp" = { };
      "7002/tcp" = { };
      "8008/tcp" = { };
    };
  };
}
