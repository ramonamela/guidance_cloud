#!/bin/bash

### PHASE 1 ###

export phasingMem="13.0"
export phasingCU="2"

export phasingBedMem="13.0"
export phasingBedCU="2"


### PHASE 2 ###

export qctoolMem="6.0"

export qctoolSMem="1.0"

export gtoolsMem="6.0"

export samtoolsBgzipMem="6.0"

export imputeWithImputeLowMem="6.0"
export imputeWithImputeMediumMem="6.0"
export imputeWithImputeHighMem="6.0"

export imputeWithMinimacLowMem="6.0"
export imputeWithMinimacMediumMem="6.0"
export imputeWithMinimacHighMem="6.0"

export filterByInfoImputeMem="6.0"

export filterByInfoMinimacMem="6.0"

### PHASE 3 ###

export createListOfExcludedSnpsMem="1.0"

export filterHaplotypesMem="1.0"

export filterByAllMem="1.0"

export jointFilteredByAllFilesMem="6.0"

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

export generateCondensedTopHitsCU="2"

export generateCondensedTopHitsMem="13.0"

export generateQQManhattanPlotsCU="2"

export generateQQManhattanPlotsMem="13.0"

export phenoMergeMem="13.0"
