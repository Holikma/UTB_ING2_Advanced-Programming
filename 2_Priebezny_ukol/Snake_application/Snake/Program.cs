using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace Snake
{
    class Program
    {
        static void Main()
        {
            Console.WindowWidth = 128;
            Console.WindowHeight = 128;

            var game = new SnakeGame(Console.WindowWidth, Console.WindowHeight);

            game.Run();
        }
    }

    internal class SnakeGame
    {
        private const char SnakeChar = '■';
        private const int FrameDelayMs = 250;
        private readonly int _width;
        private readonly int _height;
        private readonly Random _random = new();
        private readonly List<Position> _body = new();

        private Position _head;
        private Position _berry;

        private Direction _direction = Direction.Right;
        private int _score = 5;
        private bool _gameOver;

        public SnakeGame(int width, int height)
        {
            _width = width;
            _height = height;

            _head = new Position(width / 2, height / 2);
            SpawnBerry();
        }

        public void Run()
        {
            while (!_gameOver)
            {
                Render();
                ReadInput();
                Update();
            }

            ShowGameOver();
        }

        private void Update()
        {
            if (_berry.Equals(_head))
            {
                _score++;
                SpawnBerry();
            }

            _body.Add(_head);

            _head = _direction switch
            {
                Direction.Up => new Position(_head.X, _head.Y - 1),
                Direction.Down => new Position(_head.X, _head.Y + 1),
                Direction.Left => new Position(_head.X - 1, _head.Y),
                Direction.Right => new Position(_head.X + 1, _head.Y),
                _ => _head
            };

            if (_body.Count > _score)
            {
                _body.RemoveAt(0);
            }

            CheckCollisions();
        }

        private void CheckCollisions()
        {
            bool hitWall =
                _head.X <= 0 ||
                _head.X >= _width - 1 ||
                _head.Y <= 0 ||
                _head.Y >= _height - 1;

            bool hitSelf = _body.Any(segment => segment.Equals(_head));

            _gameOver = hitWall || hitSelf;
        }

        private void ReadInput()
        {
            DateTime start = DateTime.Now;
            bool directionChanged = false;

            while ((DateTime.Now - start).TotalMilliseconds < FrameDelayMs)
            {
                if (!Console.KeyAvailable)
                    continue;

                var key = Console.ReadKey(true).Key;

                if (directionChanged)
                    continue;

                switch (key)
                {
                    case ConsoleKey.UpArrow when _direction != Direction.Down:
                        _direction = Direction.Up;
                        directionChanged = true;
                        break;

                    case ConsoleKey.DownArrow when _direction != Direction.Up:
                        _direction = Direction.Down;
                        directionChanged = true;
                        break;

                    case ConsoleKey.LeftArrow when _direction != Direction.Right:
                        _direction = Direction.Left;
                        directionChanged = true;
                        break;

                    case ConsoleKey.RightArrow when _direction != Direction.Left:
                        _direction = Direction.Right;
                        directionChanged = true;
                        break;
                }
            }
        }

        private void Render()
        {
            Console.Clear();

            DrawBorder();

            Console.ForegroundColor = ConsoleColor.Green;

            foreach (var segment in _body)
            {
                Draw(segment, SnakeChar);
            }

            Console.ForegroundColor = ConsoleColor.Red;
            Draw(_head, SnakeChar);

            Console.ForegroundColor = ConsoleColor.Cyan;
            Draw(_berry, SnakeChar);
        }

        private void DrawBorder()
        {
            for (int x = 0; x < _width; x++)
            {
                Draw(new Position(x, 0), SnakeChar);
                Draw(new Position(x, _height - 1), SnakeChar);
            }

            for (int y = 0; y < _height; y++)
            {
                Draw(new Position(0, y), SnakeChar);
                Draw(new Position(_width - 1, y), SnakeChar);
            }
        }

        private static void Draw(Position position, char character)
        {
            Console.SetCursorPosition(position.X, position.Y);
            Console.Write(character);
        }

        private void SpawnBerry()
        {
            _berry = new Position(
                _random.Next(1, _width - 2),
                _random.Next(1, _height - 2));
        }

        private void ShowGameOver()
        {
            Console.SetCursorPosition(_width / 5, _height / 2);
            Console.WriteLine($"Game Over. Score: {_score}");
        }
    }

    internal readonly record struct Position(int X, int Y);

    internal enum Direction
    {
        Up,
        Down,
        Left,
        Right
    }
}