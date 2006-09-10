#
# TyrQuake Makefile (tested under Linux and MinGW/Msys)
#
# By default, all executables will be built. If you want to just build one,
# just type e.g. "make tyr-quake". If the build dirs haven't been created yet,
# you might need to type "make prepare" first.
# 
# Options:
# --------
# To build an executable with debugging symbols, un-comment the DEBUG=Y option
# below. You should "make clean" when switching this option on or off.
#
# To build an executable without using any of the hand written x86 assembler,
# un-comment the NO_X86_ASM option below. You should "make clean" when
# switching this option on or off.
#

TYR_VERSION_MAJOR = 0
TYR_VERSION_MINOR = 52
TYR_VERSION_BUILD =

TYR_VERSION = $(TYR_VERSION_MAJOR).$(TYR_VERSION_MINOR)$(TYR_VERSION_BUILD)

# ============================================================================
# User configurable options here:
# ============================================================================

#DEBUG=y 	# Compile with debug info
#NO_X86_ASM=y	# Compile with no x86 asm

# ============================================================================

BUILD_DIR = build

.PHONY:	default clean

# ============================================================================

# FIXME - how to detect build env reliably...?
ifeq ($(OSTYPE),msys)
TARGET_OS = WIN32
TOPDIR := $(shell pwd -W)
EXT = .exe
else
TARGET_OS = LINUX
TOPDIR := $(shell pwd)
EXT =
endif

# ============================================================================
# Helper functions
# ============================================================================

cc-version = $(shell sh $(TOPDIR)/scripts/gcc-version \
              $(if $(1), $(1), $(CC)))

cc-option = $(shell if $(CC) $(CFLAGS) $(1) -S -o /dev/null -xc /dev/null \
             > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi ;)

GCC_VERSION := $(call cc-version)

# ---------------------
# Special include dirs
# ---------------------
DX_INC    = $(TOPDIR)/dxsdk/sdk/inc
ST_INC    = $(TOPDIR)/scitech/include

# --------------
# Library stuff
# --------------
NQ_ST_LIBDIR = scitech/lib/win32/vc
QW_ST_LIBDIR = scitech/lib/win32/vc

NQ_W32_COMMON_LIBS = wsock32 winmm dxguid
NQ_W32_SW_LIBS = mgllt ddraw
NQ_W32_GL_LIBS = opengl32 comctl32

LINUX_X11_LIBDIR = /usr/X11R6/lib
NQ_LINUX_COMMON_LIBS = m X11 Xext Xxf86dga Xxf86vm
NQ_LINUX_GL_LIBS = GL

NQ_W32_SW_LFLAGS = -mwindows $(patsubst %,-l%,$(NQ_W32_SW_LIBS) $(NQ_W32_COMMON_LIBS))
NQ_W32_GL_LFLAGS = -mwindows $(patsubst %,-l%,$(NQ_W32_GL_LIBS) $(NQ_W32_COMMON_LIBS))
NQ_LINUX_SW_LFLAGS = $(patsubst %,-l%,$(NQ_LINUX_COMMON_LIBS))
NQ_LINUX_GL_LFLAGS = $(patsubst %,-l%,$(NQ_LINUX_COMMON_LIBS) $(NQ_LINUX_GL_LIBS))

# ---------------------------------------
# Define some build variables
# ---------------------------------------

CFLAGS := -Wall -Wno-trigraphs

# Enable this if you're getting pedantic again...
#ifeq ($(TARGET_OS),LINUX)
#CFLAGS += -Werror
#endif

ifdef DEBUG
CFLAGS += -g
cmd_strip = @echo "** Debug build - not stripping"
else
CFLAGS += -O2
# -funit-at-a-time is buggy for MinGW GCC > 3.2
# I'm assuming it's fixed for MinGW GCC >= 4.0 when that comes about
CFLAGS += $(shell if [ $(GCC_VERSION) -lt 0400 ] ;\
		then echo $(call cc-option,-fno-unit-at-a-time); fi ;)
CFLAGS += $(call cc-option,-fweb,)
CFLAGS += $(call cc-option,-frename-registers,)
CFLAGS += $(call cc-option,-mtune=i686,-mcpu=i686)
cmd_strip = strip
endif

# ---------------------------------------------------------
#  WIP: Getting rid of recursive make, separate build dirs
# ---------------------------------------------------------

# (sw = software renderer, gl = OpenGL renderer, sv = server)
NQSWDIR	= $(BUILD_DIR)/nqsw
NQGLDIR	= $(BUILD_DIR)/nqgl
QWSWDIR	= $(BUILD_DIR)/qwsw
QWGLDIR	= $(BUILD_DIR)/qwgl
QWSVDIR	= $(BUILD_DIR)/qwsv

BUILD_DIRS = $(NQSWDIR) $(NQGLDIR) $(QWSWDIR) $(QWGLDIR) $(QWSVDIR)
APPS =	tyr-quake$(EXT) tyr-glquake$(EXT) \
	tyr-qwcl$(EXT) tyr-glqwcl$(EXT) \
	tyr-qwsv$(EXT)

default:	all

all:	prepare $(APPS)

.PHONY:	prepare
prepare:	$(BUILD_DIRS)

COMMON_CPPFLAGS := -DTYR_VERSION=$(TYR_VERSION)
ifdef DEBUG
COMMON_CPPFLAGS += -DDEBUG
else
COMMON_CPPFLAGS += -DNDEBUG
endif

ifdef NO_X86_ASM
COMMON_CPPFLAGS += -U__i386__
endif

NQSW_CPPFLAGS := -DTYR_VERSION=$(TYR_VERSION) -DNQ_HACK
NQGL_CPPFLAGS := -DTYR_VERSION=$(TYR_VERSION) -DNQ_HACK -DGLQUAKE
QWSW_CPPFLAGS := -DTYR_VERSION=$(TYR_VERSION) -DQW_HACK
QWGL_CPPFLAGS := -DTYR_VERSION=$(TYR_VERSION) -DQW_HACK -DGLQUAKE
QWSV_CPPFLAGS := -DTYR_VERSION=$(TYR_VERSION) -DQW_HACK -DSERVERONLY

NQSW_CPPFLAGS += -I$(TOPDIR)/include -I$(TOPDIR)/NQ
NQGL_CPPFLAGS += -I$(TOPDIR)/include -I$(TOPDIR)/NQ
QWSW_CPPFLAGS += -I$(TOPDIR)/include -I$(TOPDIR)/QW/client
QWGL_CPPFLAGS += -I$(TOPDIR)/include -I$(TOPDIR)/QW/client
QWSV_CPPFLAGS += -I$(TOPDIR)/include -I$(TOPDIR)/QW/server -I$(TOPDIR)/QW/client

ifeq ($(TARGET_OS),WIN32)
NQSW_CPPFLAGS += -idirafter $(DX_INC) -idirafter $(ST_INC)
NQGL_CPPFLAGS += -idirafter $(DX_INC)
QWSW_CPPFLAGS += -idirafter $(DX_INC) -idirafter $(ST_INC)
QWGL_CPPFLAGS += -idirafter $(DX_INC)
endif

ifeq ($(TARGET_OS),LINUX)
NQSW_CPPFLAGS += -DELF -DX11
NQGL_CPPFLAGS += -DELF -DX11
QWSW_CPPFLAGS += -DELF -DX11
QWGL_CPPFLAGS += -DELF -DX11 -DGL_EXT_SHARED
QWSV_CPPFLAGS += -DELF
endif

define cmd_cc__
$(CC) -MM -MT $@ $($(1)) -o $(@D)/.$(@F).d $<
$(CC) -c $($(1)) $(CFLAGS) -o $@ $<
endef

DEPFILES = \
	$(wildcard $(BUILD_DIR)/nqsw/.*.d) \
	$(wildcard $(BUILD_DIR)/nqgl/.*.d) \
	$(wildcard $(BUILD_DIR)/qwsw/.*.d) \
	$(wildcard $(BUILD_DIR)/qwgl/.*.d) \
	$(wildcard $(BUILD_DIR)/qwsv/.*.d)

ifneq ($(DEPFILES),)
-include $(DEPFILES)
endif

cmd_nqsw_cc = $(call cmd_cc__,NQSW_CPPFLAGS)
cmd_nqgl_cc = $(call cmd_cc__,NQGL_CPPFLAGS)
cmd_qwsw_cc = $(call cmd_cc__,QWSW_CPPFLAGS)
cmd_qwgl_cc = $(call cmd_cc__,QWGL_CPPFLAGS)
cmd_qwsv_cc = $(call cmd_cc__,QWSV_CPPFLAGS)

define cmd_windres__
$(CC) -x c-header -MM -MT $@ $($(1)) -o $(@D)/.$(@F).d $<
windres -I $(<D) -i $< -O coff -o $@
endef

cmd_nqsw_windres = $(call cmd_windres__,NQSW_CPPFLAGS)
cmd_nqgl_windres = $(call cmd_windres__,NQGL_CPPFLAGS)
cmd_qwsw_windres = $(call cmd_windres__,QWSW_CPPFLAGS)
cmd_qwgl_windres = $(call cmd_windres__,QWGL_CPPFLAGS)

cmd_mkdir = @if [ ! -d $@ ]; then echo mkdir -p $@; mkdir -p $@; fi

$(NQSWDIR):	; $(cmd_mkdir)
$(NQGLDIR):	; $(cmd_mkdir)
$(QWSWDIR):	; $(cmd_mkdir)
$(QWGLDIR):	; $(cmd_mkdir)
$(QWSVDIR):	; $(cmd_mkdir)

$(BUILD_DIR)/nqsw/%.o:		common/%.S	; $(cmd_nqsw_cc)
$(BUILD_DIR)/nqsw/%.o:		NQ/%.S		; $(cmd_nqsw_cc)
$(BUILD_DIR)/nqsw/%.o:		common/%.c	; $(cmd_nqsw_cc)
$(BUILD_DIR)/nqsw/%.o:		NQ/%.c		; $(cmd_nqsw_cc)
$(BUILD_DIR)/nqsw/%.res:	common/%.rc	; $(cmd_nqsw_windres)
$(BUILD_DIR)/nqsw/%.res:	NQ/%.rc		; $(cmd_nqsw_windres)

$(BUILD_DIR)/nqgl/%.o:		common/%.S	; $(cmd_nqgl_cc)
$(BUILD_DIR)/nqgl/%.o:		NQ/%.S		; $(cmd_nqgl_cc)
$(BUILD_DIR)/nqgl/%.o:		common/%.c	; $(cmd_nqgl_cc)
$(BUILD_DIR)/nqgl/%.o:		NQ/%.c		; $(cmd_nqgl_cc)
$(BUILD_DIR)/nqgl/%.res:	common/%.rc	; $(cmd_nqgl_windres)
$(BUILD_DIR)/nqgl/%.res:	NQ/%.rc		; $(cmd_nqgl_windres)

$(BUILD_DIR)/qwsw/%.o:		common/%.S	; $(cmd_qwsw_cc)
$(BUILD_DIR)/qwsw/%.o:		QW/client/%.S	; $(cmd_qwsw_cc)
$(BUILD_DIR)/qwsw/%.o:		QW/common/%.S	; $(cmd_qwsw_cc)
$(BUILD_DIR)/qwsw/%.o:		common/%.c	; $(cmd_qwsw_cc)
$(BUILD_DIR)/qwsw/%.o:		QW/client/%.c	; $(cmd_qwsw_cc)
$(BUILD_DIR)/qwsw/%.o:		QW/common/%.c	; $(cmd_qwsw_cc)
$(BUILD_DIR)/qwsw/%.res:	common/%.rc	; $(cmd_qwsw_windres)
$(BUILD_DIR)/qwsw/%.res:	QW/client/%.rc	; $(cmd_qwsw_windres)

$(BUILD_DIR)/qwgl/%.o:		common/%.S	; $(cmd_qwgl_cc)
$(BUILD_DIR)/qwgl/%.o:		QW/client/%.S	; $(cmd_qwgl_cc)
$(BUILD_DIR)/qwgl/%.o:		QW/common/%.S	; $(cmd_qwgl_cc)
$(BUILD_DIR)/qwgl/%.o:		common/%.c	; $(cmd_qwgl_cc)
$(BUILD_DIR)/qwgl/%.o:		QW/client/%.c	; $(cmd_qwgl_cc)
$(BUILD_DIR)/qwgl/%.o:		QW/common/%.c	; $(cmd_qwgl_cc)
$(BUILD_DIR)/qwgl/%.res:	common/%.rc	; $(cmd_qwgl_windres)
$(BUILD_DIR)/qwgl/%.res:	QW/client/%.rc	; $(cmd_qwgl_windres)

$(BUILD_DIR)/qwsv/%.o:		common/%.S	; $(cmd_qwsv_cc)
$(BUILD_DIR)/qwsv/%.o:		QW/server/%.S	; $(cmd_qwsv_cc)
$(BUILD_DIR)/qwsv/%.o:		QW/common/%.S	; $(cmd_qwsv_cc)
$(BUILD_DIR)/qwsv/%.o:		common/%.c	; $(cmd_qwsv_cc)
$(BUILD_DIR)/qwsv/%.o:		QW/server/%.c	; $(cmd_qwsv_cc)
$(BUILD_DIR)/qwsv/%.o:		QW/common/%.c	; $(cmd_qwsv_cc)

# ----------------------------------------------------------------------------
# Normal Quake (NQ)
# ----------------------------------------------------------------------------

# Objects common to all versions of NQ, sources are c code
NQ_COMMON_C_OBJS = \
	chase.o		\
	cl_demo.o	\
	cl_input.o	\
	cl_main.o	\
	cl_parse.o	\
	cl_tent.o	\
	cmd.o		\
	common.o	\
	console.o	\
	crc.o		\
	cvar.o		\
	host.o		\
	host_cmd.o	\
	keys.o		\
	mathlib.o	\
	menu.o		\
	net_dgrm.o	\
	net_loop.o	\
	net_main.o	\
	net_vcr.o	\
	pr_cmds.o	\
	pr_edict.o	\
	pr_exec.o	\
	r_part.o	\
	\
	rb_tree.o	\
	\
	sbar.o		\
	\
	shell.o		\
	\
	snd_dma.o	\
	snd_mem.o	\
	snd_mix.o	\
	sv_main.o	\
	sv_move.o	\
	sv_phys.o	\
	sv_user.o	\
	view.o		\
	wad.o		\
	world.o		\
	zone.o

NQ_COMMON_ASM_OBJS = \
	math.o		\
	snd_mixa.o	\
	worlda.o

# Used in both SW and GL versions of NQ on the Win32 platform
NQ_W32_C_OBJS = \
	cd_win.o	\
	conproc.o	\
	in_win.o	\
	net_win.o	\
	net_wins.o	\
	net_wipx.o	\
	snd_win.o	\
	sys_win.o

NQ_W32_ASM_OBJS = \
	sys_wina.o

# Used in both SW and GL versions on NQ on the Linux platform
NQ_LINUX_C_OBJS = \
	cd_linux.o	\
	net_udp.o	\
	net_bsd.o	\
	snd_linux.o	\
	sys_linux.o	\
	x11_core.o	\
	in_x11.o

NQ_LINUX_ASM_OBJS = \
	sys_dosa.o

# Objects only used in software rendering versions of NQ
NQ_SW_C_OBJS = \
	d_edge.o	\
	d_fill.o	\
	d_init.o	\
	d_modech.o	\
	d_part.o	\
	d_polyse.o	\
	d_scan.o	\
	d_sky.o		\
	d_sprite.o	\
	d_surf.o	\
	d_vars.o	\
	d_zpoint.o	\
	draw.o		\
	model.o		\
	r_aclip.o	\
	r_alias.o	\
	r_bsp.o		\
	r_draw.o	\
	r_edge.o	\
	r_efrag.o	\
	r_light.o	\
	r_main.o	\
	r_misc.o	\
	r_sky.o		\
	r_sprite.o	\
	r_surf.o	\
	r_vars.o	\
	screen.o

NQ_SW_ASM_OBJS = \
	d_draw.o	\
	d_draw16.o	\
	d_parta.o	\
	d_polysa.o	\
	d_scana.o	\
	d_spr8.o	\
	d_varsa.o	\
	r_aclipa.o	\
	r_aliasa.o	\
	r_drawa.o	\
	r_edgea.o	\
	r_varsa.o	\
	surf16.o	\
	surf8.o

# Objects only used in software rendering versions of NQ on the Win32 Platform
NQ_W32_SW_C_OBJS = \
	vid_win.o

NQ_W32_SW_ASM_OBJS = \
	dosasm.o

# Objects only used in software rendering versions of NQ on the Linux Platform
NQ_LINUX_SW_C_OBJS = \
	vid_x.o

NQ_LINUX_SW_AMS_OBJS =

# Objects only used in OpenGL rendering versions of NQ
NQ_GL_C_OBJS = \
	drawhulls.o	\
	gl_draw.o	\
	gl_mesh.o	\
	gl_model.o	\
	gl_refrag.o	\
	gl_rlight.o	\
	gl_rmain.o	\
	gl_rmisc.o	\
	gl_rsurf.o	\
	gl_screen.o	\
	gl_warp.o

NQ_GL_ASM_OBJS =

# Objects only used in OpenGL rendering versions of NQ on the Win32 Platform
NQ_W32_GL_C_OBJS = \
	gl_vidnt.o

NQ_W32_GL_ASM_OBJS =

# Objects only used in OpenGL rendering versions of NQ on the Linux Platform
NQ_LINUX_GL_C_OBJS = \
	gl_vidlinuxglx.o

NQ_LINUX_GL_ASM_OBJS =

# Misc objects that don't seem to get used...
NQ_OTHER_ASM_OBJS = \
	d_copy.o	\
	sys_dosa.o

NQ_OTHER_C_OBJS = 

# =========================================================================== #

# Build the list of object files for each particular target
# (*sigh* - something has to be done about this makefile...)

NQ_W32_SW_OBJS := $(NQ_COMMON_C_OBJS)
NQ_W32_SW_OBJS += $(NQ_SW_C_OBJS)
NQ_W32_SW_OBJS += $(NQ_W32_C_OBJS)
NQ_W32_SW_OBJS += $(NQ_W32_SW_C_OBJS)
NQ_W32_SW_OBJS += winquake.res
ifdef NO_X86_ASM
NQ_W32_SW_OBJS += nonintel.o
else
NQ_W32_SW_OBJS += $(NQ_COMMON_ASM_OBJS)
NQ_W32_SW_OBJS += $(NQ_SW_ASM_OBJS)
NQ_W32_SW_OBJS += $(NQ_W32_ASM_OBJS)
NQ_W32_SW_OBJS += $(NQ_W32_SW_ASM_OBJS)
endif

NQ_W32_GL_OBJS := $(NQ_COMMON_C_OBJS)
NQ_W32_GL_OBJS += $(NQ_GL_C_OBJS)
NQ_W32_GL_OBJS += $(NQ_W32_C_OBJS)
NQ_W32_GL_OBJS += $(NQ_W32_GL_C_OBJS)
NQ_W32_GL_OBJS += winquake.res
ifndef NO_X86_ASM
NQ_W32_GL_OBJS += $(NQ_COMMON_ASM_OBJS)
NQ_W32_GL_OBJS += $(NQ_GL_ASM_OBJS)
NQ_W32_GL_OBJS += $(NQ_W32_ASM_OBJS)
NQ_W32_GL_OBJS += $(NQ_W32_GL_ASM_OBJS)
endif

NQ_LINUX_SW_OBJS := $(NQ_COMMON_C_OBJS)
NQ_LINUX_SW_OBJS += $(NQ_SW_C_OBJS)
NQ_LINUX_SW_OBJS += $(NQ_LINUX_C_OBJS)
NQ_LINUX_SW_OBJS += $(NQ_LINUX_SW_C_OBJS)
ifdef NO_X86_ASM
NQ_LINUX_SW_OBJS += nonintel.o
else
NQ_LINUX_SW_OBJS += $(NQ_COMMON_ASM_OBJS)
NQ_LINUX_SW_OBJS += $(NQ_SW_ASM_OBJS)
NQ_LINUX_SW_OBJS += $(NQ_LINUX_ASM_OBJS)
NQ_LINUX_SW_OBJS += $(NQ_LINUX_SW_ASM_OBJS)
endif

NQ_LINUX_GL_OBJS := $(NQ_COMMON_C_OBJS)
NQ_LINUX_GL_OBJS += $(NQ_GL_C_OBJS)
NQ_LINUX_GL_OBJS += $(NQ_LINUX_C_OBJS)
NQ_LINUX_GL_OBJS += $(NQ_LINUX_GL_C_OBJS)
ifndef NO_X86_ASM
NQ_LINUX_GL_OBJS += $(NQ_COMMON_ASM_OBJS)
NQ_LINUX_GL_OBJS += $(NQ_GL_ASM_OBJS)
NQ_LINUX_GL_OBJS += $(NQ_LINUX_ASM_OBJS)
NQ_LINUX_GL_OBJS += $(NQ_LINUX_GL_ASM_OBJS)
endif

# ------------------------
# Now, the build rules...
# ------------------------

# Win32
tyr-quake.exe:	$(patsubst %,$(NQSWDIR)/%,$(NQ_W32_SW_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(NQ_ST_LIBDIR) $(NQ_W32_SW_LFLAGS)
	$(cmd_strip) $@

tyr-glquake.exe:	$(patsubst %,$(NQGLDIR)/%,$(NQ_W32_GL_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(NQ_ST_LIBDIR) $(NQ_W32_GL_LFLAGS)
	$(cmd_strip) $@

# Linux
tyr-quake:	$(patsubst %,$(NQSWDIR)/%,$(NQ_LINUX_SW_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(LINUX_X11_LIBDIR) $(NQ_LINUX_SW_LFLAGS)
	$(cmd_strip) $@

tyr-glquake:	$(patsubst %,$(NQGLDIR)/%,$(NQ_LINUX_GL_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(LINUX_X11_LIBDIR) $(NQ_LINUX_GL_LFLAGS)
	$(cmd_strip) $@


# ----------------------------------------------------------------------------
# QuakeWorld (QW) - Client
# ----------------------------------------------------------------------------

QW_SV_SHARED_C_OBJS = \
	cmd.o		\
	common.o	\
	crc.o		\
	cvar.o		\
	mathlib.o	\
	md4.o		\
	net_chan.o	\
	pmove.o		\
	pmovetst.o	\
	rb_tree.o	\
	shell.o		\
	zone.o

QW_COMMON_C_OBJS = \
	$(QW_SV_SHARED_C_OBJS) \
	cl_cam.o	\
	cl_demo.o	\
	cl_ents.o	\
	cl_input.o	\
	cl_main.o	\
	cl_parse.o	\
	cl_pred.o	\
	cl_tent.o	\
	console.o	\
	keys.o		\
	menu.o		\
	r_part.o	\
	sbar.o		\
	skin.o		\
	snd_dma.o	\
	snd_mem.o	\
	snd_mix.o	\
	view.o		\
	wad.o

QW_COMMON_ASM_OBJS = \
	math.o		\
	snd_mixa.o

QW_W32_C_OBJS = \
	cd_win.o	\
	in_win.o	\
	net_wins.o	\
	snd_win.o	\
	sys_win.o

QW_W32_ASM_OBJS = \
	sys_wina.o

QW_LINUX_SV_SHARED_C_OBJS = \
	net_udp.o

QW_LINUX_C_OBJS = \
	$(QW_LINUX_SV_SHARED_C_OBJS) \
	cd_linux.o	\
	snd_linux.o	\
	sys_linux.o	\
	in_x11.o	\
	x11_core.o

QW_LINUX_ASM_OBJS = \
	sys_dosa.o

QW_SW_C_OBJS = \
	d_edge.o	\
	d_fill.o	\
	d_init.o	\
	d_modech.o	\
	d_part.o	\
	d_polyse.o	\
	d_scan.o	\
	d_sky.o		\
	d_sprite.o	\
	d_surf.o	\
	d_vars.o	\
	d_zpoint.o	\
	draw.o		\
	model.o		\
	r_aclip.o	\
	r_alias.o	\
	r_bsp.o		\
	r_draw.o	\
	r_edge.o	\
	r_efrag.o	\
	r_light.o	\
	r_main.o	\
	r_misc.o	\
	r_sky.o		\
	r_sprite.o	\
	r_surf.o	\
	r_vars.o	\
	screen.o

QW_SW_ASM_OBJS = \
	d_draw.o	\
	d_draw16.o	\
	d_parta.o	\
	d_polysa.o	\
	d_scana.o	\
	d_spr8.o	\
	d_varsa.o	\
	r_aclipa.o	\
	r_aliasa.o	\
	r_drawa.o	\
	r_edgea.o	\
	r_varsa.o	\
	surf16.o	\
	surf8.o

QW_W32_SW_C_OBJS = \
	vid_win.o

QW_W32_SW_ASM_OBJS =

QW_LINUX_SW_C_OBJS = \
	vid_x.o

QW_LINUX_SW_ASM_OBJS =

QW_GL_C_OBJS = \
	drawhulls.o	\
	gl_draw.o	\
	gl_mesh.o	\
	gl_model.o	\
	gl_ngraph.o	\
	gl_refrag.o	\
	gl_rlight.o	\
	gl_rmain.o	\
	gl_rmisc.o	\
	gl_rsurf.o	\
	gl_screen.o	\
	gl_warp.o

QW_GL_ASM_OBJS =

QW_W32_GL_C_OBJS = \
	gl_vidnt.o

QW_W32_GL_ASM_OBJS =

QW_LINUX_GL_C_OBJS = \
	gl_vidlinuxglx.o

QW_LINUX_GL_ASM_OBJS =

# ========================================================================== #

# Build the list of object files for each particular target
# (*sigh* - something has to be done about this makefile...)

QW_W32_SW_OBJS := $(QW_COMMON_C_OBJS)
QW_W32_SW_OBJS += $(QW_SW_C_OBJS)
QW_W32_SW_OBJS += $(QW_W32_C_OBJS)
QW_W32_SW_OBJS += $(QW_W32_SW_C_OBJS)
QW_W32_SW_OBJS += winquake.res
ifdef NO_X86_ASM
QW_W32_SW_OBJS += nonintel.o
else
QW_W32_SW_OBJS += $(QW_COMMON_ASM_OBJS)
QW_W32_SW_OBJS += $(QW_SW_ASM_OBJS)
QW_W32_SW_OBJS += $(QW_W32_ASM_OBJS)
QW_W32_SW_OBJS += $(QW_W32_SW_ASM_OBJS)
endif

QW_W32_GL_OBJS := $(QW_COMMON_C_OBJS)
QW_W32_GL_OBJS += $(QW_GL_C_OBJS)
QW_W32_GL_OBJS += $(QW_W32_C_OBJS)
QW_W32_GL_OBJS += $(QW_W32_GL_C_OBJS)
QW_W32_GL_OBJS += winquake.res
ifndef NO_X86_ASM
QW_W32_GL_OBJS += $(QW_COMMON_ASM_OBJS)
QW_W32_GL_OBJS += $(QW_GL_ASM_OBJS)
QW_W32_GL_OBJS += $(QW_W32_ASM_OBJS)
QW_W32_GL_OBJS += $(QW_W32_GL_ASM_OBJS)
endif

QW_LINUX_SW_OBJS := $(QW_COMMON_C_OBJS)
QW_LINUX_SW_OBJS += $(QW_SW_C_OBJS)
QW_LINUX_SW_OBJS += $(QW_LINUX_C_OBJS)
QW_LINUX_SW_OBJS += $(QW_LINUX_SW_C_OBJS)
ifdef NO_X86_ASM
QW_LINUX_SW_OBJS += nonintel.o
else
QW_LINUX_SW_OBJS += $(QW_COMMON_ASM_OBJS)
QW_LINUX_SW_OBJS += $(QW_SW_ASM_OBJS)
QW_LINUX_SW_OBJS += $(QW_LINUX_ASM_OBJS)
QW_LINUX_SW_OBJS += $(QW_LINUX_SW_ASM_OBJS)
endif

QW_LINUX_GL_OBJS := $(QW_COMMON_C_OBJS)
QW_LINUX_GL_OBJS += $(QW_GL_C_OBJS)
QW_LINUX_GL_OBJS += $(QW_LINUX_C_OBJS)
QW_LINUX_GL_OBJS += $(QW_LINUX_GL_C_OBJS)
ifndef NO_X86_ASM
QW_LINUX_GL_OBJS += $(QW_COMMON_ASM_OBJS)
QW_LINUX_GL_OBJS += $(QW_GL_ASM_OBJS)
QW_LINUX_GL_OBJS += $(QW_LINUX_ASM_OBJS)
QW_LINUX_GL_OBJS += $(QW_LINUX_GL_ASM_OBJS)
endif

# ---------
# QW Libs
# ---------
QW_W32_COMMON_LIBS = wsock32 dxguid winmm
QW_W32_SW_LIBS = mgllt
QW_W32_GL_LIBS = opengl32 comctl32

QW_LINUX_COMMON_LIBS = m X11 Xext Xxf86dga Xxf86vm
QW_LINUX_GL_LIBS = GL

QW_W32_SW_LFLAGS = -mwindows $(patsubst %,-l%,$(QW_W32_SW_LIBS) $(QW_W32_COMMON_LIBS))
QW_W32_GL_LFLAGS = -mwindows $(patsubst %,-l%,$(QW_W32_GL_LIBS) $(QW_W32_COMMON_LIBS))
QW_LINUX_SW_LFLAGS = $(patsubst %,-l%,$(QW_LINUX_COMMON_LIBS))
QW_LINUX_GL_LFLAGS = $(patsubst %,-l%,$(QW_LINUX_COMMON_LIBS) $(QW_LINUX_GL_LIBS))

# ---------------------
# build rules
# --------------------

# Win32
tyr-qwcl.exe:	$(patsubst %,$(QWSWDIR)/%,$(QW_W32_SW_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(QW_ST_LIBDIR) $(QW_W32_SW_LFLAGS)
	$(cmd_strip) $@

tyr-glqwcl.exe:	$(patsubst %,$(QWGLDIR)/%,$(QW_W32_GL_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ $(QW_W32_GL_LFLAGS)
	$(cmd_strip) $@

# Linux
tyr-qwcl:	$(patsubst %,$(QWSWDIR)/%,$(QW_LINUX_SW_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(LINUX_X11_LIBDIR) $(QW_LINUX_SW_LFLAGS)
	$(cmd_strip) $@

tyr-glqwcl:	$(patsubst %,$(QWGLDIR)/%,$(QW_LINUX_GL_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ -L$(LINUX_X11_LIBDIR) $(QW_LINUX_GL_LFLAGS)
	$(cmd_strip) $@

UNUSED_OBJS	= cd_audio.o

# --------------------------------------------------------------------------
# QuakeWorld (QW) - Server
# --------------------------------------------------------------------------

QWSV_SHARED_OBJS = \
	cmd.o		\
	common.o	\
	crc.o		\
	cvar.o		\
	mathlib.o	\
	md4.o		\
	net_chan.o	\
	pmove.o		\
	pmovetst.o	\
	rb_tree.o	\
	shell.o		\
	zone.o

QWSV_W32_SHARED_OBJS = \
	net_wins.o

QWSV_LINUX_SHARED_OBJS = \
	net_udp.o

QWSV_ONLY_OBJS = \
	model.o		\
	pr_cmds.o	\
	pr_edict.o	\
	pr_exec.o	\
	sv_ccmds.o	\
	sv_ents.o	\
	sv_init.o	\
	sv_main.o	\
	sv_move.o	\
	sv_nchan.o	\
	sv_phys.o	\
	sv_send.o	\
	sv_user.o	\
	world.o

QWSV_W32_ONLY_OBJS = \
	sys_win.o

QWSV_LINUX_ONLY_OBJS = \
	sys_unix.o

QWSV_W32_OBJS = \
	$(QWSV_SHARED_OBJS) 	\
	$(QWSV_W32_SHARED_OBJS)	\
	$(QWSV_ONLY_OBJS)	\
	$(QWSV_W32_ONLY_OBJS)

QWSV_LINUX_OBJS = \
	$(QWSV_SHARED_OBJS) 		\
	$(QWSV_LINUX_SHARED_OBJS)	\
	$(QWSV_ONLY_OBJS)		\
	$(QWSV_LINUX_ONLY_OBJS)

# ----------------
# QWSV Libs
# ----------------
QWSV_W32_LIBS = wsock32 winmm
QWSV_W32_LFLAGS = -mconsole $(patsubst %,-l%,$(QWSV_W32_LIBS))
QWSV_LINUX_LIBS = m
QWSV_LINUX_LFLAGS = $(patsubst %,-l%,$(QWSV_LINUX_LIBS))

# -------------
# Build rules
# -------------

# Win32
tyr-qwsv.exe:	$(patsubst %,$(QWSVDIR)/%,$(QWSV_W32_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ $(QWSV_W32_LFLAGS)
	$(cmd_strip) $@

# Linux
tyr-qwsv:	$(patsubst %,$(QWSVDIR)/%,$(QWSV_LINUX_OBJS))
	$(CC) $(CFLAGS) -o $@ $^ $(QWSV_LINUX_LFLAGS)
	$(cmd_strip) $@

# ----------------------------------------------------------------------------
# Very basic clean target (can't use xargs on MSYS)
# ----------------------------------------------------------------------------

# Main clean function...
clean:
	@rm -rf build
	@rm -f $(shell find . \( \
		-name '*~' -o -name '#*#' -o -name '*.o' -o -name '*.res' \
	\) -print)
