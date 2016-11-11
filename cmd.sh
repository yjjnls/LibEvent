__dir__=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


########################
# Enviroment Check
if [[ -z $SCA_PUBLIC_MOUNT_POINT || ! -d $SCA_PUBLIC_MOUNT_POINT ]] ; then
    error "Invalid enviroment var 'SCA_PUBLIC_MOUNT_POINT'"
	error "If you didn't init sca builder, please use command 'source sca init'"
	exit 1
fi


_ARCH=x86
_BUILDTOOL=LINUX
_CONFIG=release

case $1 in
    release)
	;;
	debug)
	_CONFIG=debug
	;;
	cmake-check)
	shift
	$__dir__/cmake-check/cmd.sh $@
	exit $?
	;;
	*)
	;;
esac


[ "$__VSYEAR__"   = "2013" ] && _BUILDTOOL=VS2013
[ "$__VSYEAR__"   = "2010" ] && _BUILDTOOL=VS2010
[ ! -z "$__CENTOSVERSION__" ] && _BUILDTOOL=CENTOS$__CENTOSVERSION__
[ ! -z "$__UBUNTUVERSION__" ] && _BUILDTOOL=UBUNTU$__UBUNTUVERSION__

[ "$__MSVCBITS__" = "32"  ]   && _ARCH=x86
[ "$__MSVCBITS__" = "64"  ]   && _ARCH=x64
[ "$__CENTOSBITS__" = "32" ]  && _ARCH=x86
[ "$__CENTOSBITS__" = "64" ]  && _ARCH=x64
[ "$__UBUNTUBITS__" = "32" ]  && _ARCH=x86
[ "$__UBUNTUBITS__" = "64" ]  && _ARCH=x64



_PWD=$(pwd)
[ ! -d $_PWD ] && mkdir -p $_PWD

_BWD="$(pwd)/~build/$_BUILDTOOL-$_ARCH-$_CONFIG"
[ ! -d $_BWD ] && mkdir -p $_BWD


export _PWD
export _BWD


function sca_make(){
	local filename=
	local type=
	local config='release'
	
	#set -- `getopt -q f:h "$@"`  
	while [ -n "$1" ]  
		do  
			case "$1" in  
				-h)  
					echo "option -h"
					;;  
				-f)   
					filename="$2"
					shift
					;;
					
				exe) type='exe';; 
				lib) type='lib';;
				dll) type='dll';; 

				debug) config='debug';; 
				release) config='release';;
				*) 
				error "invalid option $1"
				return 1
				;;  
			esac  
		shift  
	done  
		
	if [ -z $filename ]; then
		[ -f 'EXE.BUILD' ] && filename=EXE.BUILD && type=EXE
		[ -f 'LIB.BUILD' ] && filename=LIB.BUILD && type=LIB
		[ -f 'DLL.BUILD' ] && filename=DLL.BUILD && type=DLL
	else
		if [ ! -f $filename ] ;then
			error you specified build script : $filename not exit !
			return 1
		fi
		if [ -z $type ] ; then
			error "you didn't specify the build script type ( exe or lib )"
			return 1
		fi 
	fi
	_TYPE=$type
	_CONFIG=$config
	
	#######################
	local d=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
	source $filename


	export name
	export version
	export packages
	export SDK
	
	export _SDKD=$SCA_PUBLIC_MOUNT_POINT/$SDK
	export _INCD=$_SDKD/include
	export _LIBD=$_SDKD/lib/$_BUILDTOOL/$_ARCH/$_CONFIG
	export _BIND=$_SDKD/bin/$_BUILDTOOL/$_ARCH/$_CONFIG
	export _SHARED=$_SDKD/share
	export _PKGD=$_LIBD/pkgconfig
	_PKG_CONFIG_PATH=$_PKGD
	#calc pkg-config paths
    for d in $( ls $SCA_PUBLIC_MOUNT_POINT/ )
	do
		pkgd=$SCA_PUBLIC_MOUNT_POINT/$d/lib/$_BUILDTOOL/$_ARCH/$_CONFIG/pkgconfig
		if [ -d $pkgd ] ; then
		_PKG_CONFIG_PATH=$_PKG_CONFIG_PATH:$pkgd
		fi
	done
	export PKG_CONFIG_PATH=$_PKG_CONFIG_PATH:${GSTREAMER_ROOT}/lib/pkgconfig

	[ ! -d $_INCD ] && mkdir -p $_INCD
	[ ! -d $_LIBD ] && mkdir -p $_LIBD
	[ ! -d $_BIND ] && mkdir -p $_BIND
	[ ! -d $_PKGD ] && mkdir -p $_PKGD
	[ ! -d $_SHARED ] && mkdir -p $_SHARED
	msg_blue "    Building moudle ($type) $name-$version ($_CONFIG) of SDK $SDK by $_BUILDTOOL ($_ARCH)"
	cmd //c chcp 65001 > /tmp/null.txt

	###################
	prepare 
	if [ $? -ne 0 ] ; then
	   error "build for $name-$version (prepare)"
	   return 2
	fi

	#build
	#if [ $? -ne 0 ] ; then
	#   error "build for $name-$version (build)"
	#   return 3
	#fi
	
	msg_green "    ========================================="
	msg_green "    $name-$version($_ARCH) make done!"
	msg_green "    ========================================="
	
    unset name
	unset version
	unset packages
}

function _CMakeLists()
{
	local __dir__=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	local INCD=$_INCD
	local LIBD=$_LIBD
	local BIND=$_BIND
	local SHARED=$_SHARED
	local PRJD=$_PWD
	if [ ! -z $MSYSTEM ] ; then

		PRJD=$(  cygpath -w -m $PRJD   )
		INCD=$(  cygpath -w -m $INCD   )
		LIBD=$(  cygpath -w -m $LIBD   )
		BIND=$(  cygpath -w -m $BIND   )
		SHARED=$(cygpath -w -m $SHARED )

	fi


	echo -e "
	cmake_minimum_required(VERSION 2.8 )

	SET(PROJECT_DIRECTORY 
	#       \"project root directory\" 
		\"$PRJD\" )
		
	SET(PROJECT_NAME
	#       \"Project name\"
		$name )
	SET(PROJECT_TYPE
	#       \"Project type EXE|DLL|LIB\"
		$_TYPE )
		
	SET(PROJECT_CONFIG
	#       \"Project config release|debug\"
		$_CONFIG)
	SET(PROJECT_DEP_PACKAGES
	#       \"The project dependent package list \"
		${packages[*]})

	SET(PROJECT_INC_INSTALL_DIRECTORY   
	#\"\"   
		\"$INCD\" )

	SET(PROJECT_LIB_INSTALL_DIRECTORY   
	#\"\"   
		\"$LIBD\" )

	SET(PROJECT_BIN_INSTALL_DIRECTORY   
	#\"\"   
		\"$BIND\" )

	SET(PROJECT_SHARE_INSTALL_DIRECTORY 
	#\"\"   
		\"$SHARED/$name\")

	PROJECT( \${PROJECT_NAME} )

	INCLUDE( sca.cmake )
	">$_BWD/CMakeLists.txt
	cp -f /opt/sca/commands/make/sca.cmake $_BWD/sca.cmake
}




function _cmake(){
	local tool=$(echo   $_BUILDTOOL   |   tr   [a-z]   [A-Z]) 
	local arch=$(echo   $_ARCH   |   tr   [a-z]   [A-Z]) 
	if [ "$tool" = "VS2010" ] ; then
		cmake $@ -G"Visual Studio 10"
	
	elif [ "$tool" = "VS2013" ] ; then
		if [ "$arch" = "X64" ] ; then
			cmake $@ -G"Visual Studio 12 Win64"
		else
			cmake $@ -G"Visual Studio 12"
		fi
		
	elif [[ "$_BUILDTOOL" = "LINUX" || "$_BUILDTOOL" = CENTOS* || "$_BUILDTOOL" = UBUNTU* ]] ; then
		cmake $@ -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=$_CONFIG
	fi
	
	if [ $? -ne 0 ] ; then
	   error "$0" "CMake failed  ($@)" 1
       return 1
	fi
}

function _msbuild(){
	tool=$(echo   $_BUILDTOOL   |   tr   [a-z]   [A-Z]) 

	if [ "$tool" = "VS2010" ] ; then
		msbuild.exe $@  //p:PlatformTarget=$_ARCH //p:Configuration=$_CONFIG //p:PlatformToolset=v100
	elif [ "$tool" = "VS2013" ] ; then
		
		msbuild.exe $@  //p:PlatformTarget=$_ARCH //p:Configuration=$_CONFIG //p:PlatformToolset=v120	
	fi
		if [ $? -ne 0 ] ; then
		error "$0" "MSBuild failed ($@)" 1
		return 1
		fi
		return 0

}

function _prepare(){
   	#local __dir__=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    #
    #export PKG_CONFIG_PATH=$_PKGD:$PKG_CONFIG_PATH
	#echo PKG_CONFIG_PATH:$PKG_CONFIG_PATH
    cd $_BWD
	
	_CMakeLists
    
	_cmake .

}



function _build(){
	if [[ "$_BUILDTOOL" = "LINUX" || "$_BUILDTOOL" = CENTOS* || "$_BUILDTOOL" = UBUNTU* ]]; then
		make
	else
		_msbuild $name.vcxproj
	fi
}

function _makepc(){
	local __dir__=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	filename=${name}
	for i in $@
	do
		case $i in
			-f*)
			filename=${i:2}
			;;
		esac
	done
	[ ! -d $_PKGD ] && mkdir -p $_PKGD
	source $__dir__/functions/makepc.sh $@ > $_PKGD/${filename}.pc
}

function _install(){
	if [[ "$_BUILDTOOL" = "LINUX" || "$_BUILDTOOL" = CENTOS* || "$_BUILDTOOL" = UBUNTU* ]]; then
		make install
	else
		_msbuild INSTALL.vcxproj
	fi

	_makepc -l${name}
#    export PKG_CONFIG_PATH=$( echo $PKG_CONFIG_PATH | cut -d : -f 2- )
}


function prepare(){
 _prepare 
}
function build()  {
 _build   
}
function install(){
 _install 
}

sca_make $@
