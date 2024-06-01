{ lib, callPackage, fetchFromGitHub, fetchurl, fetchpatch, stdenv, pkgsi686Linux }:

let
  generic = args: let
    imported = import ./generic.nix args;
  in callPackage imported {
    lib32 = (pkgsi686Linux.callPackage imported {
      libsOnly = true;
      kernel = null;
    }).out;
  };

  kernel = callPackage # a hacky way of extracting parameters from callPackage
    ({ kernel, libsOnly ? false }: if libsOnly then { } else kernel) { };

  selectHighestVersion = a: b: if lib.versionOlder a.version b.version
    then b
    else a;

  # https://forums.developer.nvidia.com/t/linux-6-7-3-545-29-06-550-40-07-error-modpost-gpl-incompatible-module-nvidia-ko-uses-gpl-only-symbol-rcu-read-lock/280908/19
  rcu_patch = fetchpatch {
    url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
    hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
  };
in
rec {
  mkDriver = generic;

  # Official Unix Drivers - https://www.nvidia.com/en-us/drivers/unix/
  # Branch/Maturity data - http://people.freedesktop.org/~aplattner/nvidia-versions.txt

  # Policy: use the highest stable version as the default (on our master).
  stable = if stdenv.hostPlatform.system == "i686-linux" then legacy_390 else latest;

  production = generic {
    version = "550.78";
    sha256_64bit = "sha256-NAcENFJ+ydV1SD5/EcoHjkZ+c/be/FQ2bs+9z+Sjv3M=";
    sha256_aarch64 = "sha256-2POG5RWT2H7Rhs0YNfTGHO64Q8u5lJD9l/sQCGVb+AA=";
    openSha256 = "sha256-cF9omNvfHx6gHUj2u99k6OXrHGJRpDQDcBG3jryf41Y=";
    settingsSha256 = "sha256-lZiNZw4dJw4DI/6CI0h0AHbreLm825jlufuK9EB08iw=";
    persistencedSha256 = "sha256-qDGBAcZEN/ueHqWO2Y6UhhXJiW5625Kzo1m/oJhvbj4=";
  };

  latest = selectHighestVersion production (generic {
    version = "550.54.14";
    sha256_64bit = "sha256-jEl/8c/HwxD7h1FJvDD6pP0m0iN7LLps0uiweAFXz+M=";
    sha256_aarch64 = "sha256-sProBhYziFwk9rDAR2SbRiSaO7RMrf+/ZYryj4BkLB0=";
    openSha256 = "sha256-F+9MWtpIQTF18F2CftCJxQ6WwpA8BVmRGEq3FhHLuYw=";
    settingsSha256 = "sha256-m2rNASJp0i0Ez2OuqL+JpgEF0Yd8sYVCyrOoo/ln2a4=";
    persistencedSha256 = "sha256-XaPN8jVTjdag9frLPgBtqvO/goB5zxeGzaTU0CdL6C4=";
  });

  beta = selectHighestVersion latest (generic {
    version = "555.42.02";
    sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
    sha256_aarch64 = "sha256-ekx0s0LRxxTBoqOzpcBhEKIj/JnuRCSSHjtwng9qAc0=";
    openSha256 = "sha256-3/eI1VsBzuZ3Y6RZmt3Q5HrzI2saPTqUNs6zPh5zy6w=";
    settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
    persistencedSha256 = "sha256-3ae31/egyMKpqtGEqgtikWcwMwfcqMv2K4MVFa70Bqs=";
  });

  # Vulkan developer beta driver
  # See here for more information: https://developer.nvidia.com/vulkan-driver
  vulkan_beta = generic rec {
    version = "550.40.63";
    persistencedVersion = "550.54.14";
    settingsVersion = "550.54.14";
    sha256_64bit = "sha256-YvlNgxcFsCl3DzHFpKe+VXzfc0QIgf3N/hTKsWZ7gDE=";
    openSha256 = "sha256-mITh1kdSPtB+jP6TDHw04EN7gRx48KGbzbLO0wTSS/U=";
    settingsSha256 = "sha256-m2rNASJp0i0Ez2OuqL+JpgEF0Yd8sYVCyrOoo/ln2a4=";
    persistencedSha256 = "sha256-XaPN8jVTjdag9frLPgBtqvO/goB5zxeGzaTU0CdL6C4=";
    url = "https://developer.nvidia.com/downloads/vulkan-beta-${lib.concatStrings (lib.splitVersion version)}-linux";
  };

  # data center driver compatible with current default cudaPackages
  dc = dc_520;
  dc_520 = generic rec {
    version = "520.61.05";
    url = "https://us.download.nvidia.com/tesla/${version}/NVIDIA-Linux-x86_64-${version}.run";
    sha256_64bit = "sha256-EPYWZwOur/6iN/otDMrNDpNXr1mzu8cIqQl8lXhQlzU==";
    fabricmanagerSha256 = "sha256-o8Kbmkg7qczKQclaGvEyXNzEOWq9ZpQZn9syeffnEiE==";
    useSettings = false;
    usePersistenced = false;
    useFabricmanager = true;

    patches = [ rcu_patch ];

    broken = kernel.kernelAtLeast "6.5";
  };

  dc_535 = generic rec {
    version = "535.154.05";
    url = "https://us.download.nvidia.com/tesla/${version}/NVIDIA-Linux-x86_64-${version}.run";
    sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
    persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";
    fabricmanagerSha256 = "sha256-/HQfV7YA3MYVmre/sz897PF6tc6MaMiS/h7Q10m2p/o=";
    useSettings = false;
    usePersistenced = true;
    useFabricmanager = true;

    patches = [ rcu_patch ];
  };

  # Update note:
  # If you add a legacy driver here, also update `top-level/linux-kernels.nix`,
  # adding to the `nvidia_x11_legacy*` entries.

  # Last one without the bug reported here:
  # https://bbs.archlinux.org/viewtopic.php?pid=2155426#p2155426
  legacy_535 = generic {
    version = "535.154.05";
    sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
    sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
    openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
    settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
    persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";

    patches = [ rcu_patch ];
  };

  # Last one supporting Kepler architecture
  legacy_470 = generic {
    version = "470.239.06";
    sha256_64bit = "sha256-fXTKrBQKBDLXnr6OQzDceW85un3UCz/NYd92AYG/nMw=";
    sha256_aarch64 = "sha256-NZj8OLQ0N7y3V7UBamLyJE8AbI3alZJD1weNjnssuNs=";
    settingsSha256 = "sha256-2YTk6DaoB8Qvob9/ohtHXuDhxGO9O/SUwlXXbLSgJP0=";
    persistencedSha256 = "sha256-wLrkfD8MQ8sMODE+yEnWg/1ETxYVWOqNsIj1dY+5yjc=";
  };

  # Last one supporting x86
  legacy_390 = generic {
    version = "390.157";
    sha256_32bit = "sha256-VdZeCkU5qct5YgDF8Qgv4mP7CVHeqvlqnP/rioD3B5k=";
    sha256_64bit = "sha256-W+u8puj+1da52BBw+541HxjtxTSVJVPL3HHo/QubMoo=";
    settingsSha256 = "sha256-uJZO4ak/w/yeTQ9QdXJSiaURDLkevlI81de0q4PpFpw=";
    persistencedSha256 = "sha256-NuqUQbVt80gYTXgIcu0crAORfsj9BCRooyH3Gp1y1ns=";

    broken = kernel.kernelAtLeast "6.2";

    # fixes the bug described in https://bbs.archlinux.org/viewtopic.php?pid=2083439#p2083439
    # see https://bbs.archlinux.org/viewtopic.php?pid=2083651#p2083651
    # and https://bbs.archlinux.org/viewtopic.php?pid=2083699#p2083699
    postInstall = ''
      mv $out/lib/tls/* $out/lib
      rmdir $out/lib/tls
    '';
  };

  legacy_340 = let
    # Source corresponding to https://aur.archlinux.org/packages/nvidia-340xx-dkms
    aurPatches = fetchFromGitHub {
      owner = "archlinux-jerry";
      repo = "nvidia-340xx";
      rev = "7616dfed253aa93ca7d2e05caf6f7f332c439c90";
      hash = "sha256-1qlYc17aEbLD4W8XXn1qKryBk2ltT6cVIv5zAs0jXZo=";
    };
    patchset = [
      "0001-kernel-5.7.patch"
      "0002-kernel-5.8.patch"
      "0003-kernel-5.9.patch"
      "0004-kernel-5.10.patch"
      "0005-kernel-5.11.patch"
      "0006-kernel-5.14.patch"
      "0007-kernel-5.15.patch"
      "0008-kernel-5.16.patch"
      "0009-kernel-5.17.patch"
      "0010-kernel-5.18.patch"
      "0011-kernel-6.0.patch"
      "0012-kernel-6.2.patch"
      "0013-kernel-6.3.patch"
      "0014-kernel-6.5.patch"
      "0015-kernel-6.6.patch"
    ];
  in generic {
    version = "340.108";
    sha256_32bit = "1jkwa1phf0x4sgw8pvr9d6krmmr3wkgwyygrxhdazwyr2bbalci0";
    sha256_64bit = "06xp6c0sa7v1b82gf0pq0i5p0vdhmm3v964v0ypw36y0nzqx8wf6";
    settingsSha256 = "0zm29jcf0mp1nykcravnzb5isypm8l8mg2gpsvwxipb7nk1ivy34";
    persistencedSha256 = "1ax4xn3nmxg1y6immq933cqzw6cj04x93saiasdc0kjlv0pvvnkn";
    useGLVND = false;

    broken = kernel.kernelAtLeast "6.7";
    patches = map (patch: "${aurPatches}/${patch}") patchset;

    # fixes the bug described in https://bbs.archlinux.org/viewtopic.php?pid=2083439#p2083439
    # see https://bbs.archlinux.org/viewtopic.php?pid=2083651#p2083651
    # and https://bbs.archlinux.org/viewtopic.php?pid=2083699#p2083699
    postInstall = ''
      mv $out/lib/tls/* $out/lib
      rmdir $out/lib/tls
    '';
  };
}
