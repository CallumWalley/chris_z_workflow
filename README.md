## Get Repo ##

```
git clone https://github.com/CallumWalley/chris_z_workflow.git
```

## Setup ##

``LOG_LOCATION`` is where you want the output logs to go.
``SCRIPT_LOCATION`` Is the path containing the MATLAB scripts needed to run.

```
LOG_LOCATION="/nesi/nobackup/aut02787/"
WORKING_LOCATION="/nesi/project/aut02787/"
SCRIPT_LOCATION="/nesi/project/aut02787/scripts/"   #e.g. this repo.
```

Job stages defined at top of ``new_stock.sh`` under ``stage_definition()``
Arument is name of the script in ``/scripts`` to use.
First step gets input from user input, all other steps gets output of previous.

Currently:
```
stage_definition(){
    stage "AutomateRun"
    stage "ReConstructLOBAsk"
    stage "ReConstructLOBBid"
    stage "SignedDvolBuy"
    stage "SignedDvolSell"
    }
```
But you may want to change this.

## File Tree ##
```
$WORKING_LOCATION/
├── ACR/
│   ├── AutomateRun/
│   │   ├── AutomateRun_submit.sh
│   │   ├── AutomateRun_collect.sh
│   │   ├── mat_files
│   │   |   ├── ACR_AutomateRun-1.mat
│   │   |   ├── ...
│   │   |   ├── ...
│   │   |   └── ACR_AutomateRun-615.mat
│   │   └── ACR.mat
│   ├── ReConstructLOBAsk/
│   │   └── ...
│   ├── ReConstructLOBBid/
│   │   └── ...
│   ├── SignedDvolBuy/
│   │   └── ...
│   └── SignedDvolSell/
│       └── ...
└── ...
```
and
```
├── new_stock.sh
├── scripts/
│   ├── new_stock.sh
│   ├── merge.m
│   ├── AutomateRun.m
│   ├── AskSideVariables.m
│   └── ...
```
## How To ##

1. Run ``new_stock.sh``
2. You will be prompted:
```
Enter stock name: ACR
```

For this example I am using 'ACR' as the stock name.

3. If ``ACR.mat`` exists in your working directory, that will be selected as first input, if not enter the path manually.

4. Confirm Path to first input.

```
Is  "/nesi/project/nesi99999/Callum/chris_z/new_workflow/ACR.mat" your input? (y/n)
```

5. File tree for ``ACR`` as shown above will be generated.

6. Edit header of ``bash ACR/AutomateRun/AutomateRun_submit.sh`` if neccisary (most importantly ``time`` and ``mem``),
if doing test run, set ``rows``to some smaller number. On running again rows which have already been proccesssed will be skipped.

```
stock_suffix="AutomateRun"
stock_name="ACR"                                 
time="04:00:00"
mem="5000"
rows="615" # out of 615
mail_user="none"
```

7. Run first stage ``bash ACR/AutomateRun/AutomateRun_submit.sh``

8. When finished run script to validate and merge. ``ACR/AutomateRun/AutomateRun_collect.sh`` This will create a single .mat file ``ACR/AutomateRun/ACR.mat``.

9. Run next stage ``bash ACR/ReConstructLOBAsk/ReConstructLOBAsk_submit.sh``

10. Repeat.
