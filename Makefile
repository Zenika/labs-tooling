init:
	terraform -chdir="infrastructure" init --backend=true

lint: init
	terraform fmt --diff --recursive
	terraform -chdir=infrastructure init --backend=false
	terraform -chdir=infrastructure validate
