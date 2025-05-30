# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit dune
MYPV=${PV/_/-}

TagId=Geneweb-1eaac340
DESCRIPTION="Genealogy software program with a Web interface"
HOMEPAGE="https://github.com/geneweb/geneweb"
SRC_URI="https://github.com/${PN}/${PN}/archive/refs/tags/v${MYPV}.tar.gz
	-> ${P}.tar.gz"

S="${WORKDIR}"/${PN}-${MYPV}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm64 x86"
IUSE="+ocamlopt test"
RESTRICT="strip
	!test? ( test )"

DEPEND="
	acct-group/geneweb
	acct-user/geneweb
	dev-ml/calendars:=
	>=dev-ml/camlp5-8.03.00:=[ocamlopt?]
	dev-ml/camlp-streams:=
	dev-ml/jingoo:=
	dev-ml/markup:=
	dev-ml/num:=
	dev-ml/ppx_deriving:=
	dev-ml/ppx_import:=
	dev-ml/re:=
	dev-ml/stdlib-shims
	dev-ml/unidecode:=
	dev-ml/uucp:=
	dev-ml/uunf:=
	dev-ml/uutf:=
	dev-ml/zarith:=
"
RDEPEND="${DEPEND}"
BDEPEND="
	dev-ml/cppo
	>=dev-ml/dune-2.9
	dev-ml/findlib
	test? ( dev-ml/ounit2 )"

PATCHES=(
	"${FILESDIR}"/${P}-gentoo.patch
	"${FILESDIR}"/${P}-nogwrepl.patch
	"${FILESDIR}"/${P}-camlp5.patch
)

src_prepare() {
	default
	sed -i \
		-e "/opam_swich_prefix_lib/s|\"lib|\"$(get_libdir)|" \
		bin/gwrepl/mk_data.ml \
		|| die
	sed -i \
		-e "s:Printexc.catch ::" \
		bin/gwb2ged/gwb2ged.ml \
		bin/gwu/gwu.ml \
		|| die
}

src_configure() {
	ocaml ./configure.ml --sosa-zarith || die
}

src_compile() {
	emake -j1 distrib
}

src_install() {
	dune_src_install
	rm "${D}"/usr/share/doc/${PF}/geneweb/LICENSE || die
	mv "${D}"/usr/share/doc/${PF}/geneweb/* "${D}"/usr/share/doc/${PF}/ || die

	dodoc ICHANGES etc/README.txt etc/a.gwf

	# Install manpages
	doman man/*

	cd distribution/gw
	insinto /usr/share/${PN}
	doins -r etc images lang setup gwd.arg

	newinitd "${FILESDIR}/geneweb.initd-r1" geneweb
	newconfd "${FILESDIR}/geneweb.confd" geneweb
}

pkg_postinst() {
	einfo "If you come from an old version you need to rebuild the database"
	einfo "\"geneweb.gwu foo -o foo.gw \" will save the database (use the previous"
	einfo "version to do that). \"geneweb.gwc foo.gw -o bar \" will restore it "
	einfo "(using the current package)"
}
