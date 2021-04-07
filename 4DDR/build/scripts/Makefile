
build:
	export CL_DIR=`pwd`/../.. && source ../../../../../../../hdk_setup.sh && ./aws_build_dcp_from_cl.sh -foreground
	
clean:
	@echo -n "Deleting build files. Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	rm -rf *.log last_log hd_visual *.str .cache .Xil ../src_post_encryption ../reports/* ../checkpoints/*
