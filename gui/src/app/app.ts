import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.sass'
})
export class App {
  protected readonly title = signal('chess');
  indexes = Array(64).fill(0).map((_, i) => 63 - i);
  wasm: any = undefined
  board = signal<Piece[]>([])
  selected?: number = undefined
  turn = true

  constructor() {
  }

  ngAfterViewInit() {
    this.loadWasm().then(() => {
      this.wasm.init()
    }).then(() => {
      this.refreshBoard()
    })
  }

  async loadWasm() {
    const response = await fetch('brojedrez.wasm')
    const bytes = await response.arrayBuffer()
    const {instance} = await WebAssembly.instantiate(bytes)
    this.wasm = instance.exports
    console.log('WASM loaded')
    console.log(this.wasm)
  }

  refreshBoard() {
    const board = [...this.board()]
    for(const index of this.indexes) {
      const piece = this.wasm.get(index)
      board[index] = piece
    }
    this.board.set(board)
  }

  cellStyle(index: number): String {
    return this.cellStyleOdd(index) + ' ' + this.cellStylePiece(index)
  }

  cellStyleOdd(index: number): String {
    if (Math.floor(index / 8) % 2) {
      if (!(index % 2)) return 'dark'
    } else {
      if (index % 2) return 'dark'
    }
    return ''
  }

  cellStylePiece(index: number): String {
    return Piece[this.board()[index]]
  }

  async cellOnClick(index: number) {
    if (this.turn === false) return
    if (!this.selected) {
      this.selected = index
      console.log('selected', index)
      return
    } else {
      this.turn = false
      const result = this.wasm.legal_move(this.selected, index)
      if (result==0) {
        this.selected = undefined
        this.refreshBoard()
        await delay(100)
        console.log('PROCESSING')
        const start = Date.now();
        this.wasm.autoplay()
        const elapsed = (Date.now() - start) / 1000
        console.log('DONE', elapsed)
        this.refreshBoard()
      }
      this.turn = true
      this.selected = undefined;
    }
  }
}

enum Piece {
  NONE,
  PAWN1,
  ROOK1,
  KNIGHT1,
  BISHOP1,
  QUEEN1,
  KING1,
  PAWN2,
  ROOK2,
  KNIGHT2,
  BISHOP2,
  QUEEN2,
  KING2,
}

function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}
