//
//  ContentView.swift
//  SwiftyUploaderDemo
//
//  Created by kejinlu on 2023/6/16.
//

import SwiftUI
import SwiftyUploader

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!").onAppear(){
                let queue = DispatchQueue(label: "com.omg.td")
                    queue.async {
                        let app = SwiftyUploader()
                        app.run()
                    }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
