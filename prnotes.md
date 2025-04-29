i've put the wakatime api key in the user table, but i'm pretty sure it should be on the api_keys table.

generated types for wakatime json:
```ts
export interface WakatimeHeartbeats2 {
    user:  User;
    range: Range;
    days:  Day[];
}

export interface Day {
    date:       Date;
    heartbeats: Heartbeat[];
}

export interface Heartbeat {
    branch:             Branch | null;
    category:           Category;
    created_at:         Date;
    cursorpos:          number | null;
    dependencies:       string[];
    entity:             string;
    id:                 string;
    is_write:           boolean;
    language:           Language | null;
    line_additions:     null;
    line_deletions:     null;
    lineno:             number | null;
    lines:              number | null;
    machine_name_id:    string;
    project:            null | string;
    project_root_count: number | null;
    time:               number;
    type:               Type;
    user_agent_id:      string;
    user_id:            string;
}

export enum Branch {
    Main = "main",
}

export enum Type {
    Domain = "domain",
    File = "file",
}

export interface Range {
    end:   number;
    start: number;
}

export enum Language {
    C = "C",
    CPlusPlus = "C++",
    CSharp = "C#",
    Java = "Java",
    JavaScript = "JavaScript",
    Python = "Python",
    Ruby = "Ruby",
}
```