import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { NgModule } from '@angular/core';
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

  cellStyle = (index: number): String => {
    return this.cellOdd(index) + ' ' + this.cellPiece(index)
  }

  cellOdd = (index: number): String => {
    if (Math.floor(index / 8) % 2) {
      if (!(index % 2)) return 'dark'
    } else {
      if (index % 2) return 'dark'
    }
    return ''
  }

  cellPiece = (index: number): String => {
    if (index == 0)  return 'rook1'
    if (index == 1)  return 'knight1'
    if (index == 2)  return 'bishop1'
    if (index == 3)  return 'king1'
    if (index == 4)  return 'queen1'
    if (index == 5)  return 'bishop1'
    if (index == 6)  return 'knight1'
    if (index == 7)  return 'rook1'
    if (index == 8)  return 'pawn1'
    if (index == 9)  return 'pawn1'
    if (index == 10) return 'pawn1'
    if (index == 11) return 'pawn1'
    if (index == 12) return 'pawn1'
    if (index == 13) return 'pawn1'
    if (index == 14) return 'pawn1'
    if (index == 15) return 'pawn1'

    if (index == 63-0)  return 'rook2'
    if (index == 63-1)  return 'knight2'
    if (index == 63-2)  return 'bishop2'
    if (index == 63-3)  return 'queen2'
    if (index == 63-4)  return 'king2'
    if (index == 63-5)  return 'bishop2'
    if (index == 63-6)  return 'knight2'
    if (index == 63-7)  return 'rook2'
    if (index == 63-8)  return 'pawn2'
    if (index == 63-9)  return 'pawn2'
    if (index == 63-10) return 'pawn2'
    if (index == 63-11) return 'pawn2'
    if (index == 63-12) return 'pawn2'
    if (index == 63-13) return 'pawn2'
    if (index == 63-14) return 'pawn2'
    if (index == 63-15) return 'pawn2'
    return ''
  }
}
