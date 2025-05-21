[working-directory: '.']
benchmark: compile
        hyperfine 'cat ./board.txt | rust/target/release/boggle-rust' 'cat ./board.txt | go/boggle' 'cat ./board.txt | haskell/boggle' --warmup 5

compile: compile-rust compile-go compile-haskell

[working-directory: 'rust']
compile-rust:
        cargo build -r

[working-directory: 'go']
compile-go:
        go build -ldflags="-s -w" -o boggle main.go

[working-directory: 'haskell']
compile-haskell:
        ghc main.hs -Wno-x-partial -O2 -o boggle
        rm main.hi
        rm main.o
        
clean: clean-rust clean-go clean-haskell

[working-directory: 'rust']
clean-rust:
        cargo clean

[working-directory: 'go']
clean-go:
        rm boggle

[working-directory: 'haskell']
clean-haskell:
        rm boggle
