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
  highlight_orig?: number = undefined
  highlight_dest?: number = undefined
  turn = true
  mode = 'play'
  times: number[] = []

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

  init() {
    this.wasm.init()
    this.refreshBoard()
  }

  undo() {
    this.wasm.undo()
    this.refreshBoard()
  }

  timeAvg() {
    const sum = this.times.reduce((a, b) => a + b, 0)
    return (sum / this.times.length).toFixed(1)
  }

  timeP25worst() {
    const sublen = this.times.length / 4
    const sum = this.times
      .sort((a, b) => b - a)
      .slice(0, sublen)
      .reduce((a, b) => a + b, 0)
    return (sum / sublen).toFixed(1)
  }

  cellStyle(index: number): String {
    return (
      this.cellStyleOdd(index) + ' ' +
      this.cellStylePiece(index) + ' ' +
      this.cellStyleSelected(index)
    )
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

  cellStyleSelected(index: number): String {
    if (this.highlight_orig === index) return 'selected'
    if (this.highlight_dest === index) return 'selected'
    return ''
  }

  async cellOnClick(index: number) {
    if (this.turn === false) return
    if (this.selected === undefined) {
      this.selected = index
      this.highlight_orig = index
      this.highlight_dest = undefined
      return
    } else {
      const result = this.wasm.move_legal(this.selected, index)
      if (result==false) {
        this.selected = index
        this.highlight_orig = index
        this.highlight_dest = undefined
      }
      if (result==true) {
        this.selected = undefined
        this.highlight_orig = undefined
        this.refreshBoard()
        await delay(100)
        console.log('PROCESSING')
        const start = Date.now();
        this.wasm.autoplay()
        const elapsed = (Date.now() - start) / 1000
        this.times.push(elapsed)
        console.log('DONE', elapsed, this.timeAvg(), this.timeP25worst())
        this.highlight_orig = this.wasm.get_highlight_orig()
        this.highlight_dest = this.wasm.get_highlight_dest()
        this.refreshBoard()
        this.turn = true
        this.selected = undefined;
      }
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
