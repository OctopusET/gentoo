# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake

CommitId=e844ffd17118c1e17d94e1ba4354c075a4577b88
DESCRIPTION="Low-precision matrix multiplication"
HOMEPAGE="https://github.com/google/gemmlowp/"
SRC_URI="https://github.com/google/${PN}/archive/${CommitId}.tar.gz
	-> ${P}.tar.gz"

S="${WORKDIR}"/${PN}-${CommitId}/contrib

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64"
IUSE="test"

BDEPEND="test? ( dev-cpp/gtest )"
RESTRICT="!test? ( test )"

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTING=$(usex test ON OFF)
	)
	cmake_src_configure
}
