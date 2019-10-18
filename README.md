## Setup ##

``LOG_LOCATION`` is where you want the output logs to go.
``SCRIPT_LOCATION`` Is the path containing the MATLAB scripts needed to run.

```
LOG_LOCATION="/nesi/nobackup/aut02787/"
SCRIPT_LOCATION="/nesi/project/aut02787/scripts/"
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
root/
│
├── new_stock.sh
├── scripts/
│   ├── merge.m
│   ├── AutomateRun.m
│   ├── AskSideVariables.m
│   └── ...
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

6. Run first stage ``bash ACR/AutomateRun/AutomateRun_submit.sh``

7. When finished run script to validate and merge. ``ACR/AutomateRun/AutomateRun_collect.sh`` This will create a single .mat file ``ACR/AutomateRun/ACR.mat``.

8. Run next stage ``bash ACR/ReConstructLOBAsk/ReConstructLOBAsk_submit.sh``

9. Repeat.
