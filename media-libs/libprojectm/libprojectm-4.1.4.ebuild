# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake-multilib

DESCRIPTION="A graphical music visualization plugin similar to milkdrop"
HOMEPAGE="https://github.com/projectM-visualizer/projectm"

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/projectM-visualizer/projectm.git"
	inherit git-r3
else
	MY_PV="${PV/_/-}"
	SRC_URI="https://github.com/projectM-visualizer/projectm/releases/download/v${MY_PV}/libprojectM-${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64 arm arm64 ~loong ppc ppc64 ~riscv sparc x86"
	S="${WORKDIR}/libprojectM-${MY_PV}"
fi

LICENSE="LGPL-2"
SLOT="4"
IUSE="gles2-only static-libs test"
RESTRICT="!test? ( test )"

RDEPEND="
	media-libs/glm
	media-libs/libglvnd[X(+)]
"

DEPEND="${RDEPEND}"

multilib_src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=$(usex test)
		-DENABLE_SDL_UI=OFF
		-DENABLE_CXX_INTERFACE=OFF
		-DENABLE_GLES=$(usex gles2-only)
		-DENABLE_SYSTEM_GLM=ON
		-DBUILD_SHARED_LIBS=$(usex static-libs OFF ON)
	)

	cmake_src_configure
}
