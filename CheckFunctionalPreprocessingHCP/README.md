Check Functional Preprocessing
==============================

# Script Description

The CheckFunctionalPreprocessing.sh script performs a series of tests on the output of the 
[Human Connectome Project][HCP] Minimal Preprocessing Pipeline functional preprocessing.

These checks are "post pipeline sanity checks" and consists of tests to make sure
that the results directory to contain functional preprocessing output exists, that
the FSF point counts are corrent for the type of functional task (resting state, 
working memory, social cognition, etc.), that event files (EV files) exist when
they should, etc.

The tests performed were developed as part of the 500 Subject Data Release project with 
the input and assistance of Greg Burgess, Staff Scientist on the HCP. 

<!-- References -->
[HCP]: http://www.humanconnectome.org
