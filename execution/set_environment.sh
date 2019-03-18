#!/bin/bash

### PHASE 1 ###

export phasingMem="50.0"
export phasingCU="48"

export phasingBedMem="50.0"
export phasingBedCU="48"


### PHASE 2 ###

export qctoolMem="16.0"

export qctoolSMem="1.0"

export gtoolsMem="6.0"

export samtoolsBgzipMem="6.0"

export imputeWithImputeLowMem="4.0"
export imputeWithImputeMediumMem="8.0"
export imputeWithImputeHighMem="32.0"

export imputeWithMinimacLowMem="8.0"
export imputeWithMinimacMediumMem="8.0"
export imputeWithMinimacHighMem="8.0"

export filterByInfoImputeMem="12.0"

export filterByInfoMinimacMem="24.0"

### PHASE 3 ###

export createListOfExcludedSnpsMem="1.0"

export filterHaplotypesMem="1.0"

export filterByAllMem="1.0"

export jointFilteredByAllFilesMem="15.0"

export jointCondensedFilesMem="1.0"

export generateTopHitsAllMem="2.0"

export generateTopHitsMem="2.0"

export filterByMafMem="2.0"

export snptestMem="2.0"

export mergeTwoChunksMem="1.0"

export mergeTwoChunksInTheFirstMem="1.0"

export combinePanelsMem="1.0"

export combineCondensedFilesMem="1.0"

export combinePanelsComplex1Mem="1.0"

### PHASE 4 ###

export generateCondensedTopHitsCU="25"

export generateCondensedTopHitsMem="40.0"

export generateQQManhattanPlotsCU="12"

export generateQQManhattanPlotsMem="40.0"

export phenoMergeMem="80.0"
