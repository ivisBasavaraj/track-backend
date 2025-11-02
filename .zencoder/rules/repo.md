# TrackPro Repository Notes

- **Tech Stack**: Flutter Web & Mobile client with Node.js/Express backend. MongoDB is the primary datastore.
- **Frontend Path**: `trackpro\lib` contains Dart screens, services, and models. State is managed with StatefulWidgets and service classes.
- **Backend Path**: `backend/` houses the Express API, using routes under `routes/` and Mongoose models in `models/`.
- **Authentication**: Supervisors authenticate through `/api/auth/login` (Express). Flutter clients must use base URL `http://localhost:3001/api` during local development.
- **Excel Uploads**: File uploads rely on `ToolsService` & `ApiService`. On web targets, use in-memory bytes rather than file system paths.
- **Known Issues**:
  - Duplicate MongoDB index definitions trigger warnings; plan to consolidate indexes.
  - `ToolManagementScreen` is partially updated for byte-based uploads and still needs refactoring.
- **Testing**: No automated test suite for Flutter yet. Manual QA via Flutter web/desktop is common.
- **targetFramework**: Playwright
- **Scripts**: Backend setup scripts live under `backend/scripts/`. Read `START_HERE.md` before local provisioning.