# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=ETHER
DIST_VERSION=0.32
inherit perl-module

DESCRIPTION="Minimal try/catch with proper localization of \$@"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
IUSE="minimal"

RDEPEND="
	!<=dev-perl/Try-Tiny-Except-0.10.0
	!minimal? (
		|| ( >=virtual/perl-Scalar-List-Utils-1.400.0 dev-perl/Sub-Name )
	)
	virtual/perl-Carp
	>=virtual/perl-Exporter-5.570.0
"
BDEPEND="
	${RDEPEND}
	virtual/perl-ExtUtils-MakeMaker
	test? (
		!minimal? (
			>=virtual/perl-CPAN-Meta-2.120.900
			>=dev-perl/Capture-Tiny-0.120.0
		)
		virtual/perl-File-Spec
		virtual/perl-Test-Simple
		virtual/perl-if
	)
"
