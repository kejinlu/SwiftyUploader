//
//  ContentView.swift
//  SwiftyUploaderDemo
//
//  Created by kejinlu on 2023/6/16.
//

import SwiftUI
import SwiftyUploader

struct ContentView: View {
    @State var uploader:SwiftyUploader?
    var body: some View {
        VStack {
            Text(uploader == nil ? "Starting...":"Started, please visit")
            Text(uploader == nil ? "":"http://"+uploader!.getIPAddress()).onAppear(){
                let queue = DispatchQueue(label: "com.kejinlu.uploaderdemo")
                    queue.async {
                        uploader = SwiftyUploader()
                        uploader?.run()
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
