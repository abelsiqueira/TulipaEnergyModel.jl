# Run from project folder with
#
#   julia --project=. utils/scripts/update-model-lp.jl
#
using TulipaEnergyModel, TulipaIO, DuckDB

model_lp_folder = joinpath("benchmark", "model-lp-folder")
if isdir(model_lp_folder)
    rm(model_lp_folder; force = true, recursive = true)
end
mkdir(model_lp_folder)

for folder in readdir("test/inputs"; join = true)
    isdir(folder) || continue

    @info "Running run_scenario for $folder"

    con = DBInterface.connect(DuckDB.DB)
    schemas = TulipaEnergyModel.schema_per_table_name
    TulipaIO.read_csv_folder(con, folder; schemas)
    TulipaEnergyModel.run_scenario(con; write_lp_file = true, show_log = false)

    lp_filename = basename(folder) * ".lp"
    @info "Storing model.lp into $model_lp_folder/$lp_filename"

    mv("model.lp", joinpath(model_lp_folder, lp_filename))
end
