//
//  CodeGenerator.swift
//  Eject
//
//  Created by Brian King on 10/18/16.
//  Copyright © 2016 Brian King. All rights reserved.
//

import Foundation

public protocol CodeGenerator {

    var dependentIdentifiers: Set<String> { get }

    func generateCode(in document: XIBDocument) -> String

}

extension CodeGenerator {
    var dependentIdentifiers: Set<String> {
        return []
    }
}

public enum CodeGeneratorPhase {
    case initialization
    case configuration
    case subviews
    case constraints
}

extension XIBDocument {

    func code(for generationPhase: CodeGeneratorPhase) -> [String] {
        return statements.filter() { $0.phase == generationPhase }.map() { $0.generator.generateCode(in: self) }
    }

    func generateCode() -> [String] {
        var context = GenerationContext(document: self)
        return context.generateCode()
    }
}

struct GenerationContext {
    let document: XIBDocument
    var statements: [Statement]
    var declared = Set<String>()


    init(document: XIBDocument) {
        self.document = document
        self.statements = document.statements
    }

    mutating func extractStatements(matching: (Statement) -> Bool) -> [Statement] {
        let matching = statements.enumerated().filter() { matching($0.element) }
        matching.reversed().map() { $0.offset }.forEach() { index in
            statements.remove(at: index)
        }
        return matching.map() { $0.element }
    }

    mutating func declaration(identifier: String) -> String? {
        let declarations = extractStatements() { $0.declares?.identifier == identifier && $0.phase == .initialization }
        guard declarations.count <= 1 else {
            fatalError("Should only have one statement to declare an identifier")
        }
        guard let declaration = declarations.first else {
            // It's valid for external references (placholders) to be un-declared
            return nil
        }

        if !declaration.generator.dependentIdentifiers.isSubset(of: declared) {
            return nil
        }
        declared.insert(declaration.declares!.identifier)
        return declaration.generator.generateCode(in: document)
    }

    mutating func configuration(identifier: String) -> [String] {
        // get statements that only depend on the specified object
        let configurations = extractStatements() {
            $0.generator.dependentIdentifiers == Set([identifier]) && $0.phase == .configuration
        }
        let code = configurations.map() { $0.generator.generateCode(in: document) }
        return code
    }

    mutating func code(for generationPhase: CodeGeneratorPhase) -> [String] {
        let code = extractStatements() { $0.phase == generationPhase }
            .reversed()
            .map() { $0.generator.generateCode(in: document) }
        return code
    }

    mutating func generateCode() -> [String] {
        var generatedCode: [String] = []
        // Generate the list of objects that need generation. This will remove the
        // placeholders since they are declared externally.
        var needGeneration = document.references.filter() { !$0.identifier.hasPrefix("-") }
        while needGeneration.count > 0 {
            var removedIndexes = IndexSet()
            for (index, reference) in needGeneration.enumerated() {
                if let code = declaration(identifier: reference.identifier) {
                    generatedCode.append(code)
                    generatedCode.append(contentsOf: configuration(identifier: reference.identifier))
                    removedIndexes.insert(index)
                }
            }
            if removedIndexes.count == 0 {
                break
            }
            for index in removedIndexes.reversed() {
                needGeneration.remove(at: index)
            }
        }
        for phase: CodeGeneratorPhase in [.subviews, .constraints, .configuration] {
            generatedCode.append(contentsOf: code(for: phase))
        }
        assert(statements.count == 0)
        return generatedCode
    }
}
