#
# Copyright 2004 Sun Microsystems, Inc.  All Rights Reserved.
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
#
# This code is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 2 only, as
# published by the Free Software Foundation.
#
# This code is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details (a copy is included in the LICENSE file that
# accompanied this code).
#
# You should have received a copy of the GNU General Public License version
# 2 along with this work; if not, write to the Free Software Foundation,
# Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Please contact Sun Microsystems, Inc., 4150 Network Circle, Santa Clara,
# CA 95054 USA or visit www.sun.com if you need additional information or
# have any questions.
#

# @test
# @bug 4990825
# @run shell/timeout=90 jstatdServerName.sh
# @summary Test functionality of 'jstatd -p <port> -n <servername>&'

. ${TESTSRC-.}/../../jvmstat/testlibrary/utils.sh

setup
verify_os

cleanup() {
  kill_proc ${JSTATD_1_PID}
  kill_proc ${JSTATD_2_PID}
}

trap 'cleanup' 0 HUP INT QUIT TERM

JSTATD="${TESTJAVA}/bin/jstatd"
JPS="${TESTJAVA}/bin/jps"
JSTAT="${TESTJAVA}/bin/jstat"

HOSTNAME=`uname -n`
PORT_1=2098
PORT_2=2099
SERVERNAME="SecondJstatdServer"

JSTATD_1_OUT="jstatd_$$_1.out"
JSTATD_2_OUT="jstatd_$$_2.out"

${JSTATD} -J-Djava.security.policy=${TESTSRC}/all.policy -p ${PORT_1} 2>&1 > ${JSTATD_1_OUT} &
JSTATD_1_PID=$!

echo "first jstatd started as pid ${JSTATD_1_PID} on port ${PORT_1} with default server name"
sleep 3

${JSTATD} -J-Djava.security.policy=${TESTSRC}/all.policy -p ${PORT_2} -n ${SERVERNAME} 2>&1 > ${JSTATD_2_OUT} &
JSTATD_2_PID=$!

echo "second jstatd started as pid ${JSTATD_2_PID} on port ${PORT_2} with name ${SERVERNAME}"
sleep 3

echo "running: ${JPS} ${HOSTNAME}:${PORT_1}"
${JPS} ${HOSTNAME}:${PORT_1} 2>&1 | awk -f ${TESTSRC}/jpsOutput1.awk

if [ $? -ne 0 ]
then
    echo "Output of jps differs from expected output. Failed."
    exit 1
fi

echo "running: ${JPS} ${HOSTNAME}:${PORT_2}/${SERVERNAME}"
${JPS} ${HOSTNAME}:${PORT_2}/${SERVERNAME} 2>&1 | awk -f ${TESTSRC}/jpsOutput1.awk

if [ $? -ne 0 ]
then
    echo "Output of jps differs from expected output. Failed."
    exit 1
fi

TARGET_PID=`${JPS} | grep "Jstatd" | cut -d" " -f1 | head -1`

echo "running: ${JSTAT} -gcutil ${TARGET_PID}@${HOSTNAME}:${PORT_1} 250 5"
${JSTAT} -gcutil ${TARGET_PID}@${HOSTNAME}:${PORT_1} 250 5 2>&1 | awk -f ${TESTSRC}/jstatGcutilOutput1.awk
RC=$?

if [ ${RC} -ne 0 ]
then
    echo "jstat output differs from expected output"
fi

echo "running: ${JSTAT} -gcutil ${TARGET_PID}@${HOSTNAME}:${PORT_2}/${SERVERNAME} 250 5"
${JSTAT} -gcutil ${TARGET_PID}@${HOSTNAME}:${PORT_2}/${SERVERNAME} 250 5 2>&1 | awk -f ${TESTSRC}/jstatGcutilOutput1.awk
RC=$?

if [ ${RC} -ne 0 ]
then
    echo "jstat output differs from expected output"
fi

if [ -s ${JSTATD_1_OUT} ]
then
    echo "first jstatd generated the following, unexpected output:"
    RC=1
fi

if [ -s ${JSTATD_2_OUT} ]
then
    echo "second jstatd generated the following, unexpected output:"
    RC=1
fi

exit ${RC}
