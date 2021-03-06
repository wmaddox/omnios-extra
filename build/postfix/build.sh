#!/usr/bin/bash
#
# {{{ CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END }}}
#
# Copyright 2011-2013 OmniTI Computer Consulting, Inc.  All rights reserved.
# Copyright 2019 OmniOS Community Edition (OmniOSce) Association.
# Use is subject to license terms.
#
. ../../lib/functions.sh

PROG=postfix
VER=3.4.5
PKG=ooce/network/smtp/postfix
SUMMARY="Postfix MTA"
DESC="Wietse Venema's mail server alternative to sendmail"

set_arch 64

SKIP_LICENCES=IPL

HARDLINK_TARGETS="
    opt/ooce/postfix/libexec/postfix/smtp
    opt/ooce/postfix/libexec/postfix/qmgr
"

OPREFIX=$PREFIX
PREFIX+="/$PROG"
CONFPATH="/etc$PREFIX"

BUILD_DEPENDS_IPS="
    library/pcre
    ooce/database/bdb
    ooce/database/lmdb
"

XFORM_ARGS="
    -DPREFIX=${PREFIX#/}
    -DOPREFIX=${OPREFIX#/}
    -DPROG=${PROG}
"

configure64() {
    logmsg "--- configure (make makefiles)"
    logcmd $MAKE makefiles CCARGS='-m64 -DUSE_TLS -DHAS_DB -DHAS_LMDB -DNO_NIS \
        -DDEF_COMMAND_DIR=\"'${PREFIX}/sbin'\" \
        -DDEF_CONFIG_DIR=\"'${CONFPATH}'\" \
        -DDEF_DAEMON_DIR=\"'${PREFIX}/libexec/postfix'\" \
        -DDEF_MAILQ_PATH=\"'${PREFIX}/bin/mailq'\" \
        -DDEF_NEWALIAS_PATH=\"'${PREFIX}/bin/newaliases'\" \
        -DDEF_MANPAGE_DIR=\"'${PREFIX}/share/man'\" \
        -DDEF_SENDMAIL_PATH=\"'${PREFIX}/sbin/sendmail'\" \
        -I'${OPREFIX}/include \
        AUXLIBS="-R${OPREFIX}/lib/${ISAPART64} -L${OPREFIX}/lib/${ISAPART64} -ldb -lssl -lcrypto" \
        AUXLIBS_LMDB="-R${OPREFIX}/lib/${ISAPART64} -L${OPREFIX}/lib/${ISAPART64} -llmdb" \
            || logerr "Failed make makefiles command"
}

make_clean() {
    logmsg "--- make (dist)clean"
    logcmd $MAKE tidy || logcmd $MAKE -f Makefile.init makefiles \
        || logmsg "--- *** WARNING *** make (dist)clean Failed"
}

# Overriding this because "install" for postfix is interactive
make_install() {
    logmsg "--- make install"
    logcmd /bin/sh postfix-install -non-interactive install_root=${DESTDIR} \
        || logerr "--- Make install failed"

    logmsg "--- change default aliases paths"
    logcmd perl -i -pe "s!^#(alias_(?:maps|database)\\s+=\\s+hash:)/etc/aliases\$!\$1${CONFPATH}/aliases!" \
        $DESTDIR$CONFPATH/main.cf || logerr "-- modifying main.cf failed"
}

init
download_source $PROG $PROG $VER
patch_source
prep_build
build
strip_install
install_smf network smtp-postfix.xml
make_package
clean_up

# Vim hints
# vim:ts=4:sw=4:et:fdm=marker
