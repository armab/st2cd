#!/bin/bash
set -e

REPO=$1
PROJECT=$2
VERSION=$3
FORK=$4
LOCAL_REPO=$5
PYPI_USERNAME=$6
PYPI_PASSWORD=$7
GIT_REPO="git@github.com:${FORK}/${REPO}.git"
SHORT_VERSION=`echo ${VERSION} | cut -d "." -f1-2`
BRANCH="v${SHORT_VERSION}"
CWD=`pwd`


# CHECK IF BRANCH EXISTS
BRANCH_EXISTS=`git ls-remote --heads ${GIT_REPO} | grep refs/heads/${BRANCH} || true`

if [[ -z "${BRANCH_EXISTS}" ]]; then
    >&2 echo "ERROR: Branch ${BRANCH} does not exist in ${GIT_REPO}."
    exit 1
fi


# GIT CLONE AND BRANCH
if [[ -z ${LOCAL_REPO} ]]; then
    CURRENT_TIMESTAMP=`date +'%s'`
    RANDOM_NUMBER=`awk -v min=100 -v max=999 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
    LOCAL_REPO=${REPO}_${CURRENT_TIMESTAMP}_${RANDOM_NUMBER}
fi

echo "Cloning ${GIT_REPO} to ${LOCAL_REPO}..."

if [ -d "${LOCAL_REPO}" ]; then
    rm -rf ${LOCAL_REPO}
fi

git clone ${GIT_REPO} ${LOCAL_REPO}

cd ${LOCAL_REPO}
echo "Currently at directory `pwd`..."
echo "Checkout out branch ${BRANCH}..."
git checkout -b ${BRANCH} origin/${BRANCH}


# WRITE PYPIRC
PYPIRC=~/.pypirc

if [ -e "${PYPIRC}" ]; then
    rm -rf ${PYPIRC}
fi

touch ${PYPIRC}
cat <<pypirc >${PYPIRC}
[distutils]
index-servers =
    pypi
    pypitest
[pypi]
repository: https://pypi.python.org/pypi
username: ${PYPI_USERNAME}
password: ${PYPI_PASSWORD}
[pypitest]
repository: https://testpypi.python.org/pypi
username: ${PYPI_USERNAME}
password: ${PYPI_PASSWORD}
pypirc

if [ ! -e "${PYPIRC}" ]; then
    >&2 echo "ERROR: Unable to write file ${PYPIRC}"
    exit 1
fi


# Upload st2client to pypi
cd ./${PROJECT}
echo "Currently at directory `pwd`..."
python setup.py sdist upload -r pypitest
python setup.py sdist upload -r pypi


# CLEANUP
cd ${CWD}
rm -rf ${LOCAL_REPO}
rm -rf ${PYPIRC}
