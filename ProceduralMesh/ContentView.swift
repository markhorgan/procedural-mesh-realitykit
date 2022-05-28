//
//  ContentView.swift
//  ProceduralMesh
//
//  Created by Mark Horgan on 27/05/2022.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    private let isShowTangentCoordinateSystems = true
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let anchorEntity = AnchorEntity(plane: .horizontal)
        let meshEntity = buildMesh(numCells: [3, 3], cellSize: 0.1)
        anchorEntity.addChild(meshEntity)
        if isShowTangentCoordinateSystems {
            showTangentCoordinateSystems(modelEntity: meshEntity, parent: anchorEntity)
        }
        arView.scene.anchors.append(anchorEntity)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    private func buildMesh(numCells: simd_int2, cellSize: Float) -> ModelEntity {
        var positions: [simd_float3] = []
        var textureCoordinates: [simd_float2] = []
        var triangleIndices: [UInt32] = []
        
        let size: simd_float2 = [Float(numCells.x) * cellSize, Float(numCells.y) * cellSize]
        // Offset is used to make the origin in the center
        let offset: simd_float2 = [size.x / 2, size.y / 2]
        var i = 0
        
        for row in 0..<numCells.y {
            for col in 0..<numCells.x {
                let x = (Float(col) * cellSize) - offset.x
                let z = (Float(row) * cellSize) - offset.y
                
                positions.append([x, 0, z])
                positions.append([x + cellSize, 0, z])
                positions.append([x, 0, z + cellSize])
                positions.append([x + cellSize, 0, z + cellSize])
                
                textureCoordinates.append([0.0, 0.0])
                textureCoordinates.append([1.0, 0.0])
                textureCoordinates.append([0.0, 1.0])
                textureCoordinates.append([1.0, 1.0])
                
                // Triangle 1
                triangleIndices.append(UInt32(i))
                triangleIndices.append(UInt32(i + 2))
                triangleIndices.append(UInt32(i + 1))
                
                // Triangle 2
                triangleIndices.append(UInt32(i + 1))
                triangleIndices.append(UInt32(i + 2))
                triangleIndices.append(UInt32(i + 3))
                
                i += 4
            }
        }
        
        var descriptor = MeshDescriptor(name: "proceduralMesh")
        descriptor.positions = MeshBuffer(positions)
        descriptor.primitives = .triangles(triangleIndices)
        descriptor.textureCoordinates = MeshBuffer(textureCoordinates)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .white, texture: .init(try! .load(named: "base_color")))
        material.normal = .init(texture: .init(try! .load(named: "normal")))
        let mesh = try! MeshResource.generate(from: [descriptor])
        
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    private func showTangentCoordinateSystems(modelEntity: ModelEntity, parent: Entity) {
        let axisLength: Float = 0.02
        
        for model in modelEntity.model!.mesh.contents.models {
            for part in model.parts {
                var positions: [simd_float3] = []
                
                for position in part.positions {
                    parent.addChild(buildSphere(position: position, radius: 0.005, color: .black))
                    positions.append(position)
                }
                
                for (i, tangent) in part.tangents!.enumerated() {
                    parent.addChild(buildSphere(position: positions[i] + (axisLength * tangent), radius: 0.0025, color: .red))
                }
                
                for (i, bitangent) in part.bitangents!.enumerated() {
                    parent.addChild(buildSphere(position: positions[i] + (axisLength * bitangent), radius: 0.0025, color: .green))
                }
                
                for (i, normal) in part.normals!.enumerated() {
                    parent.addChild(buildSphere(position: positions[i] + (axisLength * normal), radius: 0.0025, color: .blue))
                }
            }
        }
    }
    
    private func buildSphere(position: simd_float3, radius: Float, color: UIColor) -> ModelEntity {
        let sphereEntity = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
        sphereEntity.position = position
        return sphereEntity
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
