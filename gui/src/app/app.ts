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
  modeBoard = 'board'
  bot = 0
  dialog = signal('')
  dialogCounter = 0
  dialogTimer = 0
  times: number[] = []
  thinking = signal(false)

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
    const wasmImports = {
      env: {
        js_random: () => Math.floor(Math.random() * 0xFFFFFFFF),
      }
    };
    const {instance} = await WebAssembly.instantiate(bytes, wasmImports)
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
    this.highlight_orig = this.wasm.get_highlight_orig()
    this.highlight_dest = this.wasm.get_highlight_dest()
  }

  init(botId: number) {
    this.modeBoard = 'board'
    this.bot = botId
    this.wasm.init()
    this.wasm.start(botId)
    this.refreshBoard()
    this.dialogNew()
  }

  dialogNew() {
    clearTimeout(this.dialogTimer)
    const rand = Math.floor(Math.random() * dialogs.length)
    this.dialog.set(dialogs[rand])
    this.dialogTimer = setTimeout(() => {
      this.dialog.set('')
    }, 15000);
  }

  setThinking(state: boolean) {
    clearTimeout(this.dialogTimer)
    this.dialog.set('')
    this.thinking.set(state)
    if (state==false) {
      this.dialogCounter += 1
      if (this.dialogCounter > 6) {
        this.dialogNew()
        this.dialogCounter = 0
      }
    }
  }

  undo() {
    this.wasm.undo()
    this.refreshBoard()
  }

  redo() {
    this.wasm.redo()
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
        console.log('PROCESSING')
        this.setThinking(true)
        await delay(100)
        const start = Date.now();
        this.wasm.move_bot()
        const elapsed = (Date.now() - start) / 1000
        this.times.push(elapsed)
        console.log('DONE', elapsed, this.timeAvg(), this.timeP25worst())
        this.setThinking(false)
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

const dialogs = [
  'I`m not an AI, but I can say stupid shit without wasting a lot of electricity',
  'In Finland there is no horchata and no croquetas',
  'Chess game design is bad, it benefits defensive play, and punish the losing player',
  'I drove a motorbike over 300 km/h',
  'I used to have the ambulance driver license',
  'Chess skill is not a sign of intelligence, is a sign of how many hours you played chess',
  'I was expelled from school when I was 15',
  'I made 3 hobby programming languages: Dotcy, Warp, and Arecibo, all of them sucked',
  'A hammer falls faster than a feather in vacuum, by a few femtoseconds',
  'You started hallucinating reality this morning, and all your memories are being created when you "remember" them',
  'The only way to learn orbital mechanics is playing Kerbal Space Program',
  'I like the engineering of weapons, but holding weapons makes me feel uneasy',
  'My best rubik cube solve time is 24 seconds',
  'I have lucid dreams sometimes',
  'I`m still trying to find the ex-Nokia person that created the snake game',
  'Health and getting old is overrated',
  'Doing 1 hour of sports extends your life by 1 hour, so you are just extending the agony',
  'Jupiter moons can be seen with any cheap binoculars',
  'A dog thinks is family, a cat thinks is an unionized pest control employee',
  'La puerta giratoria siempre gira pero nunca toria',
  'Venus will be easier to terraform than Mars',
  'Framerate over resolution, always',
  'If you go to Black Mesa, bring your passport',
  '"Mundo viejuuuuuno"',
  '"Carmiña vacaloura non son vaca non son loura"',
  '"Si, eran 6 motoristas que eran motos, la policía lo está investigando por los nombres"',
  '"Esta pendiente es un poco... trambólico, hay que saber subir y bajar"',
  '"Pájaros del terror, pájaros del terror"',
  '"I`m stronger than an ant, if an ant was this big"',
  '"If your ball is too big for your mouth, it`s not yours"',
  '"I`m just a chair guy, and I`ve always been a chair guy"',
  'Hot take: Best game of 1999 was "Legacy of Kain: Soul Reaver"',
  'Hot take: Best game of 2008 was "Mirror`s Edge"',
  'Hot take: Best game of 2012 was "Far Cry 3"',
  'Hot take: Best game of 2016 was "Furi"',
  'Hot take: Best game of 2018 was "Celeste"',
  'Hot take: Best game of 2019 was "Outer Wilds"',
  'Hot take: Best game of 2020 was "Deep Rock Galactic"',
  'Hot take: Best game of 2022 was "Teardown"',
  'Hot take: Best game of 2025 was "White Knuckle"',
]
