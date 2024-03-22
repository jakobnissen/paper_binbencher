module load tools
module load fastani/1.34
module load julia/1.10.1
export JULIA_DEPOT_PATH="/home/projects/ku_00197/people/jakni/.julia"
julia --startup=no --project=. -t 10 src/run_fastani.jl
