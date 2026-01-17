//
//  RecipeBooksView+Import.swift
//  Reczipes2
//
//  Quick reference for adding import to your RecipeBooksView
//

/*
 ADD IMPORT BUTTON TO YOUR RECIPE BOOKS VIEW
 
 Add this to your RecipeBooksView toolbar:
 
 ToolbarItem(placement: .primaryAction) {
     Menu {
         Button {
             showingNewBook = true
         } label: {
             Label("New Book", systemImage: "plus")
         }
         
         Button {
             showingImport = true
         } label: {
             Label("Import Book", systemImage: "square.and.arrow.down")
         }
     } label: {
         Image(systemName: "plus")
     }
 }
 
 Add this state variable:
 
 @State private var showingImport = false
 
 Add this sheet modifier:
 
 .sheet(isPresented: $showingImport) {
     RecipeBookImportView()
 }
 
 ---
 
 FULL EXAMPLE:
 
 struct RecipeBooksView: View {
     @Environment(\.modelContext) private var modelContext
     @Query private var books: [RecipeBook]
     
     @State private var showingNewBook = false
     @State private var showingImport = false
     @State private var selectedBook: RecipeBook?
     
     var body: some View {
         NavigationStack {
             List {
                 ForEach(books) { book in
                     NavigationLink(value: book) {
                         RecipeBookRowView(book: book)
                     }
                 }
             }
             .navigationTitle("Recipe Books")
             .toolbar {
                 ToolbarItem(placement: .primaryAction) {
                     Menu {
                         Button {
                             showingNewBook = true
                         } label: {
                             Label("New Book", systemImage: "plus")
                         }
                         
                         Button {
                             showingImport = true
                         } label: {
                             Label("Import Book", systemImage: "square.and.arrow.down")
                         }
                     } label: {
                         Image(systemName: "plus")
                     }
                 }
             }
             .sheet(isPresented: $showingNewBook) {
                 RecipeBookEditorView()
             }
             .sheet(isPresented: $showingImport) {
                 RecipeBookImportView()
             }
             .navigationDestination(for: RecipeBook.self) { book in
                 RecipeBookDetailView(book: book)
             }
         }
     }
 }
 
 */
