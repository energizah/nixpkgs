{ stdenv, fetchFromGitHub, python37Packages, glib, cairo, pango, pkgconfig, libxcb, xcbutilcursor }:

let cairocffi-xcffib = python37Packages.cairocffi.override {
    withXcffib = true;
  };
in

python37Packages.buildPythonApplication rec {
  name = "qtile-${version}";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "qtile";
    repo = "qtile";
    rev = "v${version}";
    sha256 = "0jnpb0yg8yh8a5vgq10jlaaapdl4m6c9slq6k519ryki4a8jnq5g";
  };

  patches = [
    ./0001-Substitution-vars-for-absolute-paths.patch
    ./0002-Restore-PATH-and-PYTHONPATH.patch
    ./0003-Restart-executable.patch
  ];

  postPatch = ''
    substituteInPlace libqtile/core/manager.py --subst-var-by out $out
    substituteInPlace libqtile/pangocffi.py --subst-var-by glib ${glib.out}
    substituteInPlace libqtile/pangocffi.py --subst-var-by pango ${pango.out}
    substituteInPlace libqtile/backend/x11/xcursors.py --subst-var-by xcb-cursor ${xcbutilcursor.out}
  '';

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ glib libxcb cairo pango python37Packages.xcffib ];

  pythonPath = with python37Packages; [ xcffib cairocffi-xcffib setuptools ];

  postInstall = ''
    wrapProgram $out/bin/qtile \
      --run 'export QTILE_WRAPPER=$0' \
      --run 'export QTILE_SAVED_PYTHONPATH=$PYTHONPATH' \
      --run 'export QTILE_SAVED_PATH=$PATH'
  '';

  doCheck = false; # Requires X server.

  meta = with stdenv.lib; {
    homepage = "http://www.qtile.org/";
    license = licenses.mit;
    description = "A small, flexible, scriptable tiling window manager written in Python";
    platforms = platforms.linux;
    maintainers = with maintainers; [ kamilchm ];
  };
}
