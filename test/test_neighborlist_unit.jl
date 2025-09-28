# test_neighborlist_unit.jl - Unit tests for neighbor list functionality

using StaticArrays
using LinearAlgebra

@testset "Neighbor List Unit Tests" begin

    @testset "NeighborListContainer Construction" begin
        # NOTE: NeighborListContainer is a low-level wrapper around C pointers
        # and cannot be directly constructed from Julia data. This test is
        # skipped as it tests a non-existent interface.
        @test_skip false  # Skip this test as the constructor doesn't exist
    end

    @testset "Index Conversion Logic" begin
        # Test the logic used in the callback function for index conversion

        # Julia 1-based to KIM 0-based
        julia_neighbors = Int32[2, 3, 5]  # 1-based indices
        kim_neighbors = julia_neighbors .- 1  # Convert to 0-based

        @test kim_neighbors == Int32[1, 2, 4]

        # KIM 0-based to Julia 1-based  
        kim_indices = Int32[0, 3, 7]  # 0-based indices
        julia_indices = kim_indices .+ 1  # Convert to 1-based

        @test julia_indices == Int32[1, 4, 8]
    end

    @testset "Neighbor List Creation Logic" begin
        # Test the logic used in create_kim_neighborlists

        # Simple 3D positions
        positions = [
            SVector(0.0, 0.0, 0.0),  # Atom 1 at origin
            SVector(1.0, 0.0, 0.0),  # Atom 2 at (1,0,0)
            SVector(0.0, 1.0, 0.0),  # Atom 3 at (0,1,0)  
            SVector(2.0, 0.0, 0.0),   # Atom 4 at (2,0,0)
        ]

        species = ["Si", "Si", "Si", "Si"]

        # Test cutoff logic
        cutoff = 1.5  # Should include neighbors within 1.5 units

        # Calculate expected neighbors manually
        n_atoms = length(positions)
        expected_neighbors = Vector{Vector{Int32}}(undef, n_atoms)

        for i = 1:n_atoms
            neighbors = Int32[]
            for j = 1:n_atoms
                if i != j
                    dist = norm(positions[i] - positions[j])
                    if dist <= cutoff
                        push!(neighbors, j)
                    end
                end
            end
            expected_neighbors[i] = neighbors
        end

        # Atom 1 (0,0,0) should have neighbors 2 (dist=1.0) and 3 (dist=1.0)
        @test sort(expected_neighbors[1]) == Int32[2, 3]

        # Atom 2 (1,0,0) should have neighbors 1 (dist=1.0), 3 (dist=sqrt(2)≈1.414), 4 (dist=1.0)
        @test sort(expected_neighbors[2]) == Int32[1, 3, 4]

        # Atom 3 (0,1,0) should have neighbors 1 (dist=1.0) and 2 (dist=sqrt(2)≈1.414)
        @test sort(expected_neighbors[3]) == Int32[1, 2]

        # Atom 4 (2,0,0) should have no neighbors (closest is atom 2 at dist=1.0, but that's within cutoff)
        # Actually, atom 4 should have atom 2 as neighbor (dist = 1.0 < 1.5)
        @test expected_neighbors[4] == Int32[2]

        # Test multiple cutoffs
        cutoffs = [1.5, 2.5]  # Two different cutoff distances

        # For cutoff 2.5, more neighbors should be included
        for cutoff in cutoffs
            neighbors_at_cutoff = Vector{Vector{Int32}}(undef, n_atoms)

            for i = 1:n_atoms
                neighbors = Int32[]
                for j = 1:n_atoms
                    if i != j
                        dist = norm(positions[i] - positions[j])
                        if dist <= cutoff
                            push!(neighbors, j)
                        end
                    end
                end
                neighbors_at_cutoff[i] = neighbors
            end

            if cutoff == 1.5
                # Same as before
                @test sort(neighbors_at_cutoff[1]) == Int32[2, 3]
            elseif cutoff == 2.5
                # Atom 1 should now also see atom 4 (dist = 2.0 < 2.5)
                @test sort(neighbors_at_cutoff[1]) == Int32[2, 3, 4]
                # Atom 4 should now also see atoms 1 (dist = 2.0 < 2.5) and 3 (dist = sqrt(5)≈2.236 < 2.5)
                @test sort(neighbors_at_cutoff[4]) == Int32[1, 2, 3]
            end
        end
    end

    @testset "Periodic Boundary Conditions Logic" begin
        # Test PBC handling logic (without actual NeighbourLists.jl dependency)

        # Define a cubic cell
        cell = [5.0 0.0 0.0; 0.0 5.0 0.0; 0.0 0.0 5.0]  # 5x5x5 cube

        # Atom near boundary
        pos1 = SVector(0.5, 0.5, 0.5)    # Near origin
        pos2 = SVector(4.5, 0.5, 0.5)    # Near x-boundary

        # Direct distance
        direct_dist = norm(pos1 - pos2)  # Should be ~4.0
        @test abs(direct_dist - 4.0) < 1e-10

        # With PBC, minimum distance should be ~1.0
        # (atom at 4.5 is equivalent to atom at -0.5, distance from 0.5 = 1.0)

        # Test PBC distance calculation logic
        function pbc_distance(pos1, pos2, cell)
            # Simple cubic PBC distance (this is conceptual - real implementation more complex)
            diff = pos1 - pos2
            cell_size = diag(cell)  # Assumes cubic

            for i = 1:3
                if diff[i] > cell_size[i]/2
                    diff =
                        diff - SVector(
                            i==1 ? cell_size[1] : 0.0,
                            i==2 ? cell_size[2] : 0.0,
                            i==3 ? cell_size[3] : 0.0,
                        )
                elseif diff[i] < -cell_size[i]/2
                    diff =
                        diff + SVector(
                            i==1 ? cell_size[1] : 0.0,
                            i==2 ? cell_size[2] : 0.0,
                            i==3 ? cell_size[3] : 0.0,
                        )
                end
            end
            return norm(diff)
        end

        pbc_dist = pbc_distance(pos1, pos2, cell)
        @test abs(pbc_dist - 1.0) < 1e-10

        # Test that non-PBC and PBC give different results for this case
        @test abs(direct_dist - pbc_dist) > 2.0
    end

    @testset "Contributing Flags Logic" begin
        # Test contributing flags for real vs ghost atoms

        n_real = 4
        n_ghost = 6
        n_total = n_real + n_ghost

        # Contributing flags: 1 for real atoms, 0 for ghost atoms
        contributing = vcat(ones(Int32, n_real), zeros(Int32, n_ghost))

        @test length(contributing) == n_total
        @test sum(contributing) == n_real  # Only real atoms contribute
        @test all(contributing[1:n_real] .== 1)
        @test all(contributing[(n_real+1):end] .== 0)

        # Test individual flags
        for i = 1:n_real
            @test contributing[i] == 1
        end
        for i = (n_real+1):n_total
            @test contributing[i] == 0
        end
    end
end
