# AddResolutionPatchHCP7T

This patch pipeline was created to fix the inflated surface files that 
are created by the AddResolutionHCP7T pipeline.

After the AddResolutionHCP7T pipeline was run on all the HCP 7T subjects,
Keith Jamison noticed that there was a problem with the 59k grayordinates 
space inflated and very_inflated surfaces. 

The "inflation factor" used needs to be computed based upon the resolution
of the mesh.  Changes to the FreeSurfer2CaretConvertAndRegisterNonlinear.sh 
script and the FreeSurfer2CaretConvertAndRegisterNonlinear_1res.sh script
are necessary for this computation of the surface inflation needed.

Since the inflated and very inflated surfaces are "display only" files and
are not used as input to subsequent pipelines, rather than re-run the 
AddResolutionHCP7T pipeline after the script changes are made, this
"patch" script was created to just create the correctly inflated surfaces
and then overwrite the existing inflated surfaces in the existing DB
resource that was created by the AddResoultionHCP7T pipeline.

The script changes should still be incorporated in to the HCP Pipelines
Scripts for future use.

2016.05.19 Timothy B. Brown