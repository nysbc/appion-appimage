BASEDIR := $(shell git rev-parse --show-toplevel)
BUILDDIR := $(BASEDIR)/builddir
INSTALLDIR := /common/sw/containers/opt/appion/bin
VPATH = src $(BUILDDIR)

PYTHON_APPIMAGE := /opt/appimage/bin/python3.10.19-cp310-cp310-manylinux2014_x86_64.AppImage
APPIMAGETOOL := /opt/appimage/bin/appimagetool-x86_64.AppImage
CHMOD := /usr/bin/chmod
RM := /usr/bin/rm
CP := /usr/bin/cp
GIT := /usr/bin/git
APPION_REPO_URL := https://github.com/nysbc/appion.git
SINEDON_REPO_URL := https://github.com/nysbc/sinedon.git

$(BUILDDIR):
	mkdir -p $@

appion.AppDir: | $(BUILDDIR)
	cd $(BUILDDIR) ; \
	$(PYTHON_APPIMAGE) --appimage-extract ; \
	mv squashfs-root appion.AppDir 

PYTHON_VENV := PATH=$(BUILDDIR)/appion.AppDir/opt/python3.10/bin:$$PATH PYTHONHOME=$(BUILDDIR)/appion.AppDir/opt/python3.10/ VIRTUAL_ENV=$(BUILDDIR)/appion.AppDir/opt/python3.10 

appion.repo:
	cd $(BUILDDIR) ; \
	$(GIT) clone $(APPION_REPO_URL) appion.repo

sinedon.repo:
	cd $(BUILDDIR) ; \
	$(GIT) clone $(SINEDON_REPO_URL) sinedon.repo

appion: AppRun appion.AppDir appion.repo sinedon.repo
	$(PYTHON_VENV) python3.10 -m pip install poetry ; \
	cd $(BUILDDIR)/sinedon.repo ; \
	$(PYTHON_VENV) poetry lock ; \
	$(PYTHON_VENV) poetry install --no-root ; \
	$(PYTHON_VENV) poetry build ; \
	$(PYTHON_VENV) pip3.10 install dist/*.whl ; \
	cd $(BUILDDIR)/appion.repo ; \
	$(PYTHON_VENV) poetry lock ; \
	$(PYTHON_VENV) poetry install --no-root ; \
	$(PYTHON_VENV) poetry build ; \
	$(PYTHON_VENV) pip3.10 install dist/*.whl ; \
	$(CP) $(BUILDDIR)/appion.repo/bin/* $(BUILDDIR)/appion.AppDir/opt/python3.10/bin ; \
	cd $(BUILDDIR) ; \
	$(CP) $(BASEDIR)/src/AppRun appion.AppDir/AppRun ; \
	$(APPIMAGETOOL) appion.AppDir appion ; \
	$(CHMOD) +x appion

.PHONY: build
build: appion

.PHONY: install
install: build
	$(CP) $(BUILDDIR)/appion $(INSTALLDIR)

.PHONY: clean
clean:
	if [ -d $(BUILDDIR) ] ; then \
		$(RM) -rf $(BUILDDIR);\
	fi
