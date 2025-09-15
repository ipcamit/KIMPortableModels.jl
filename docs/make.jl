using Documenter, KIMPortableModels

# Set up documentation
makedocs(
    modules = [KIMPortableModels],
    sitename = "KIMPortableModels.jl",
    authors = "Amit Gupta <gupta839@umn.edu>",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://ipcamit.github.io/KIMPortableModels.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Adding KIM Support to Your Simulator" => "simulator_integration.md",
        "API Reference" => [
            "High-level Interface" => "api/highlevel.md",
            "Model Management" => "api/model.md",
            "Species Handling" => "api/species.md",
            "Neighbor Lists" => "api/neighborlist.md",
            "Constants & Units" => "api/constants.md",
            "Utilities" => "api/utils.md",
        ],
        "Examples" => "examples.md",
        # "Troubleshooting" => "troubleshooting.md",
        # "Developer Guide" => "developer.md"
    ],
    repo = "https://github.com/ipcamit/KIMPortableModels.jl/blob/{commit}{path}#L{line}",
    clean = true,
    doctest = false,
    linkcheck = false,
)

# Deploy documentation
deploydocs(
    repo = "github.com/ipcamit/KIMPortableModels.jl.git",
    target = "build",
    branch = "gh-pages",
    devbranch = "master",
)
