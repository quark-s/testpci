#!/bin/sh

if [ $(find ./items/items/* -maxdepth 0 -type d -printf . | wc -c) -ge "1" ]; then
	for IPATH in $( ls -d items/items/*/ )
	do
		if ! [ -d $IPATH ]; then
			return 0
		fi
		if [ $(find $IPATH -name "*.zip" -printf . | wc -c) -lt "1" ]; then
			return 0
		fi
		#GITHUB_WORKSPACE=$(pwd)
		export FOLDER=${IPATH##*/}
		rm -r ./ee/ee/public/items/*
		cp -a ${IPATH}. ./ee/ee/public/items/
		# npm install --prefix ./ee/ee
		# export REPONAME="${GITHUB_REPOSITORY#*/}"
		sed -i 's@"homepage": ".*"@"homepage": "./"@' ./ee/ee/package.json
		cd ./ee/ee && npm run build
		find ./build/ -name *.map -exec rm {} \;
		cd $GITHUB_WORKSPACE
		mkdir -p ./pci_specific_tao/views/js/pciCreator/ibTaoEmbedded/runtime/assets/ee
		mkdir -p ./pci_specific_ims/views/js/pciCreator/ibTaoConnector/runtime/assets/ee
		cp -a ./ee/ee/build/. ./pci_specific_tao/views/js/pciCreator/ibTaoEmbedded/runtime/assets/ee	
		cp -a ./ee/ee/build/. ./pci_specific_ims/views/js/pciCreator/ibTaoConnector/runtime/assets/ee

		cd ./pci_specific_tao/scripts/packer
		npm i           
		node ./index.js -i "$PATH" -l "${REPONAME}_${FOLDER}_specific_tao_$(date '+%D-%H:%M')" -o "$GITHUB_WORKSPACE"
		cd $GITHUB_WORKSPACE

		cd ./pci_specific_ims/scripts/packer
		npm i           
		node ./index.js -i "$PATH" -l "${REPONAME}_${FOLDER}_specific_ims_$(date '+%D-%H:%M')" -o "$GITHUB_WORKSPACE"
		cd $GITHUB_WORKSPACE

		###### generic pci & github pages
		sed -i 's@"homepage": ".*"@"homepage": "/'"$REPONAME"'/'"$FOLDER"'/"@' ./ee/ee/package.json
		(cd ./ee/ee && npm run build)
		cp -a ./ee/ee/build/. ./public/${FOLDER}/

		cd ./pci_generic_tao/scripts/packer
		npm i           
		node ./index.js -u "https://${GITHUB_REPOSITORY_OWNER}.github.io/${REPONAME}/${FOLDER}" -i "${GITHUB_WORKSPACE}/${PATH}" -l "${REPONAME}_${FOLDER}_generic_tao_$(date '+%D-%H:%M')" -o "$GITHUB_WORKSPACE"
		cd $GITHUB_WORKSPACE

		cd ./pci_generic_ims/scripts/packer
		npm i           
		node ./index.js -u "https://${GITHUB_REPOSITORY_OWNER}.github.io/${REPONAME}/${FOLDER}" -i "${GITHUB_WORKSPACE}/${PATH}" -l "${REPONAME}_${FOLDER}_generic_ims_$(date '+%D-%H:%M')" -o "$GITHUB_WORKSPACE"
		cd $GITHUB_WORKSPACE 
		tar -cvf ${FOLDER}.tar *.zip
	done
fi
