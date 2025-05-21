[working-directory: '.']
benchmark: compile
        hyperfine 'cat ./board.txt | rust/target/release/boggle-rust' 'cat ./board.txt | go/boggle' --warmup 5

compile: compile-rust compile-go compile-haskell

[working-directory: 'rust']
compile-rust:
        cargo build -r

[working-directory: 'go']
compile-go:
        go build

[working-directory: 'haskell']
compile-haskell:
        ghc main.hs -Wno-x-partial
        
clean: clean-rust clean-go clean-haskell

[working-directory: 'rust']
clean-rust:
        cargo clean

[working-directory: 'go']
clean-go:
        rm boggle

[working-directory: 'haskell']
clean-haskell:
        rm main main.hi main.o
